import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, Tabs, message, Checkbox, Collapse, Tooltip, Badge } from 'antd';
import { EditOutlined, InfoCircleOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons';
import type { CravingSlotsData, CravingSlotMapping, TimeSlotsData, TimeSlot, DimensionDefinitions, FineDimension, CharacterClassesData, CharacterTraitsData, SlotModifier } from '../types';
import { loadCravingSlots, saveCravingSlots, loadTimeSlots, loadDimensionDefinitions, loadCharacterClasses, loadCharacterTraits } from '../api';

const { TextArea } = Input;
const { Panel } = Collapse;

// Helper to convert RGB [0-1] to hex color string
const rgbToHex = (color: [number, number, number]): string => {
  const r = Math.round(color[0] * 255);
  const g = Math.round(color[1] * 255);
  const b = Math.round(color[2] * 255);
  return `#${r.toString(16).padStart(2, '0')}${g.toString(16).padStart(2, '0')}${b.toString(16).padStart(2, '0')}`;
};

const CravingSlotManager: React.FC = () => {
  const [data, setData] = useState<CravingSlotsData | null>(null);
  const [timeSlots, setTimeSlots] = useState<TimeSlot[]>([]);
  const [dimensions, setDimensions] = useState<FineDimension[]>([]);
  const [classes, setClasses] = useState<{ id: string; name: string }[]>([]);
  const [traits, setTraits] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingDimension, setEditingDimension] = useState<string | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [activeTab, setActiveTab] = useState<string>('mappings');
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadAllData();
  }, []);

  const loadAllData = async () => {
    setLoading(true);
    try {
      const [slotsData, cravingSlotsData, dimensionData, classData, traitData] = await Promise.all([
        loadTimeSlots(),
        loadCravingSlots(),
        loadDimensionDefinitions(),
        loadCharacterClasses(),
        loadCharacterTraits()
      ]);

      setTimeSlots(slotsData.slots);
      setData(cravingSlotsData);
      setDimensions(dimensionData.fineDimensions);
      setClasses(classData.classes.map(c => ({ id: c.id, name: c.name })));
      setTraits(traitData.traits.map(t => ({ id: t.id, name: t.name })));
    } catch (error) {
      message.error('Failed to load data');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: CravingSlotsData) => {
    try {
      await saveCravingSlots(newData);
      setData(newData);
      message.success('Craving slot mappings saved successfully');
    } catch (error) {
      message.error('Failed to save craving slot mappings');
      console.error(error);
    }
  };

  const handleEditMapping = (dimensionId: string) => {
    setEditingDimension(dimensionId);
    const mapping = data?.mappings[dimensionId];
    form.setFieldsValue({
      slots: mapping?.slots || [],
      frequencyPerDay: mapping?.frequencyPerDay || 1,
      description: mapping?.description || ''
    });
    setIsModalVisible(true);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data || !editingDimension) return;

      const newMapping: CravingSlotMapping = {
        slots: values.slots || [],
        frequencyPerDay: values.frequencyPerDay || 1,
        description: values.description || ''
      };

      const newData: CravingSlotsData = {
        ...data,
        mappings: {
          ...data.mappings,
          [editingDimension]: newMapping
        }
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
      setEditingDimension(null);
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Filter dimensions by search
  const filteredDimensions = dimensions.filter(dim =>
    dim.name.toLowerCase().includes(searchText.toLowerCase()) ||
    dim.id.toLowerCase().includes(searchText.toLowerCase()) ||
    dim.parentCoarse.toLowerCase().includes(searchText.toLowerCase())
  );

  // Group dimensions by parent coarse
  const groupedDimensions = filteredDimensions.reduce((acc, dim) => {
    const parent = dim.parentCoarse;
    if (!acc[parent]) acc[parent] = [];
    acc[parent].push(dim);
    return acc;
  }, {} as Record<string, FineDimension[]>);

  const mappingColumns = [
    {
      title: 'Dimension',
      key: 'dimension',
      width: 250,
      render: (_: any, record: FineDimension) => (
        <div>
          <div style={{ fontWeight: 500 }}>{record.name}</div>
          <div style={{ fontSize: 11, color: '#888' }}>{record.id}</div>
        </div>
      )
    },
    {
      title: 'Active Slots',
      key: 'slots',
      render: (_: any, record: FineDimension) => {
        const mapping = data?.mappings[record.id];
        if (!mapping || mapping.slots.length === 0) {
          return <Tag color="default">Not configured</Tag>;
        }
        return (
          <Space wrap size={[4, 4]}>
            {mapping.slots.map(slotId => {
              const slot = timeSlots.find(s => s.id === slotId);
              return slot ? (
                <Tag
                  key={slotId}
                  color={rgbToHex(slot.color)}
                  style={{ color: '#000' }}
                >
                  {slot.name}
                </Tag>
              ) : null;
            })}
          </Space>
        );
      }
    },
    {
      title: 'Freq/Day',
      key: 'frequency',
      width: 80,
      render: (_: any, record: FineDimension) => {
        const mapping = data?.mappings[record.id];
        return mapping ? mapping.frequencyPerDay : '-';
      }
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 80,
      render: (_: any, record: FineDimension) => (
        <Button
          icon={<EditOutlined />}
          size="small"
          onClick={() => handleEditMapping(record.id)}
        >
          Edit
        </Button>
      )
    }
  ];

  // Class Modifiers Tab
  const renderClassModifiers = () => {
    if (!data) return null;

    return (
      <div>
        <p style={{ marginBottom: 16, color: '#666' }}>
          Class modifiers add or remove slots for specific character classes.
        </p>
        <Collapse>
          {classes.map(cls => {
            const modifiers = data.classModifiers[cls.id] || {};
            const modifierCount = Object.keys(modifiers).length;

            return (
              <Panel
                header={
                  <Space>
                    <span>{cls.name}</span>
                    <Badge count={modifierCount} showZero={false} style={{ backgroundColor: '#52c41a' }} />
                  </Space>
                }
                key={cls.id}
              >
                {modifierCount === 0 ? (
                  <p style={{ color: '#888' }}>No modifiers configured for this class.</p>
                ) : (
                  <Table
                    size="small"
                    pagination={false}
                    dataSource={Object.entries(modifiers).map(([dimId, mod]) => ({
                      dimensionId: dimId,
                      ...mod
                    }))}
                    columns={[
                      {
                        title: 'Dimension',
                        dataIndex: 'dimensionId',
                        render: (id: string) => {
                          const dim = dimensions.find(d => d.id === id);
                          return dim?.name || id;
                        }
                      },
                      {
                        title: 'Additional Slots',
                        dataIndex: 'additionalSlots',
                        render: (slots?: string[]) => slots?.length ? (
                          <Space>
                            {slots.map(s => {
                              const slot = timeSlots.find(ts => ts.id === s);
                              return <Tag key={s} color="green">{slot?.name || s}</Tag>;
                            })}
                          </Space>
                        ) : '-'
                      },
                      {
                        title: 'Removed Slots',
                        dataIndex: 'removeSlots',
                        render: (slots?: string[]) => slots?.length ? (
                          <Space>
                            {slots.map(s => {
                              const slot = timeSlots.find(ts => ts.id === s);
                              return <Tag key={s} color="red">{slot?.name || s}</Tag>;
                            })}
                          </Space>
                        ) : '-'
                      },
                      {
                        title: 'Description',
                        dataIndex: 'description',
                        ellipsis: true
                      }
                    ]}
                    rowKey="dimensionId"
                  />
                )}
              </Panel>
            );
          })}
        </Collapse>
      </div>
    );
  };

  // Trait Modifiers Tab
  const renderTraitModifiers = () => {
    if (!data) return null;

    return (
      <div>
        <p style={{ marginBottom: 16, color: '#666' }}>
          Trait modifiers add or remove slots based on character traits.
        </p>
        <Collapse>
          {traits.map(trait => {
            const modifiers = data.traitModifiers[trait.id] || {};
            const modifierCount = Object.keys(modifiers).length;

            return (
              <Panel
                header={
                  <Space>
                    <span>{trait.name}</span>
                    <Badge count={modifierCount} showZero={false} style={{ backgroundColor: '#1890ff' }} />
                  </Space>
                }
                key={trait.id}
              >
                {modifierCount === 0 ? (
                  <p style={{ color: '#888' }}>No modifiers configured for this trait.</p>
                ) : (
                  <Table
                    size="small"
                    pagination={false}
                    dataSource={Object.entries(modifiers).map(([dimId, mod]) => ({
                      dimensionId: dimId,
                      ...mod
                    }))}
                    columns={[
                      {
                        title: 'Dimension',
                        dataIndex: 'dimensionId',
                        render: (id: string) => {
                          const dim = dimensions.find(d => d.id === id);
                          return dim?.name || id;
                        }
                      },
                      {
                        title: 'Additional Slots',
                        dataIndex: 'additionalSlots',
                        render: (slots?: string[]) => slots?.length ? (
                          <Space>
                            {slots.map(s => {
                              const slot = timeSlots.find(ts => ts.id === s);
                              return <Tag key={s} color="green">{slot?.name || s}</Tag>;
                            })}
                          </Space>
                        ) : '-'
                      },
                      {
                        title: 'Removed Slots',
                        dataIndex: 'removeSlots',
                        render: (slots?: string[]) => slots?.length ? (
                          <Space>
                            {slots.map(s => {
                              const slot = timeSlots.find(ts => ts.id === s);
                              return <Tag key={s} color="red">{slot?.name || s}</Tag>;
                            })}
                          </Space>
                        ) : '-'
                      },
                      {
                        title: 'Description',
                        dataIndex: 'description',
                        ellipsis: true
                      }
                    ]}
                    rowKey="dimensionId"
                  />
                )}
              </Panel>
            );
          })}
        </Collapse>
      </div>
    );
  };

  // Summary Stats
  const getMappingStats = () => {
    if (!data) return { configured: 0, total: 0 };
    const configured = Object.keys(data.mappings).filter(
      id => data.mappings[id].slots.length > 0
    ).length;
    return { configured, total: dimensions.length };
  };

  const stats = getMappingStats();

  return (
    <div>
      <Card
        title="Craving Slot Mappings"
        extra={
          <Space>
            <Tooltip title="Configured / Total dimensions">
              <Tag color={stats.configured === stats.total ? 'success' : 'warning'}>
                {stats.configured} / {stats.total} configured
              </Tag>
            </Tooltip>
          </Space>
        }
      >
        <p style={{ marginBottom: 16, color: '#666' }}>
          Map craving dimensions to time slots. Cravings only activate during their assigned slots.
        </p>

        <Tabs
          activeKey={activeTab}
          onChange={setActiveTab}
          items={[
            {
              key: 'mappings',
              label: 'Base Mappings',
              children: (
                <div>
                  <Input.Search
                    placeholder="Search dimensions..."
                    value={searchText}
                    onChange={e => setSearchText(e.target.value)}
                    style={{ width: 300, marginBottom: 16 }}
                    allowClear
                  />

                  <Collapse defaultActiveKey={Object.keys(groupedDimensions).slice(0, 2)}>
                    {Object.entries(groupedDimensions).map(([parent, dims]) => (
                      <Panel
                        header={
                          <Space>
                            <span style={{ fontWeight: 500 }}>{parent}</span>
                            <Tag>{dims.length} dimensions</Tag>
                          </Space>
                        }
                        key={parent}
                      >
                        <Table
                          columns={mappingColumns}
                          dataSource={dims}
                          rowKey="id"
                          loading={loading}
                          pagination={false}
                          size="small"
                        />
                      </Panel>
                    ))}
                  </Collapse>
                </div>
              )
            },
            {
              key: 'class-modifiers',
              label: 'Class Modifiers',
              children: renderClassModifiers()
            },
            {
              key: 'trait-modifiers',
              label: 'Trait Modifiers',
              children: renderTraitModifiers()
            }
          ]}
        />
      </Card>

      <Modal
        title={`Edit Slot Mapping: ${editingDimension ? dimensions.find(d => d.id === editingDimension)?.name : ''}`}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
          setEditingDimension(null);
        }}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="slots"
            label="Active Slots"
            extra="Select which time slots this craving is active during"
          >
            <Checkbox.Group style={{ width: '100%' }}>
              <Space direction="vertical" style={{ width: '100%' }}>
                {timeSlots.map(slot => (
                  <Checkbox key={slot.id} value={slot.id}>
                    <Space>
                      <div
                        style={{
                          width: 16,
                          height: 16,
                          backgroundColor: rgbToHex(slot.color),
                          borderRadius: 2,
                          display: 'inline-block',
                          verticalAlign: 'middle'
                        }}
                      />
                      <span>{slot.name}</span>
                      <span style={{ color: '#888', fontSize: 12 }}>
                        ({slot.startHour}:00 - {slot.endHour}:00)
                      </span>
                    </Space>
                  </Checkbox>
                ))}
              </Space>
            </Checkbox.Group>
          </Form.Item>

          <Form.Item
            name="frequencyPerDay"
            label="Frequency Per Day"
            extra="How many times this craving activates per day"
          >
            <InputNumber min={1} max={10} style={{ width: 100 }} />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} placeholder="Why is this craving active during these slots?" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CravingSlotManager;
