import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, Tabs, message, Statistic, Row, Col, Descriptions, Popconfirm } from 'antd';
import { EditOutlined, DeleteOutlined, PlusOutlined, SettingOutlined } from '@ant-design/icons';
import type { UnitsData, CommodityUnit, PersonDayBaseline } from '../types';
import { loadUnits, saveUnits } from '../api';

const { TextArea } = Input;
const { Option } = Select;

const UnitsManager: React.FC = () => {
  const [data, setData] = useState<UnitsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingCommodity, setEditingCommodity] = useState<string | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isBaselineModalVisible, setIsBaselineModalVisible] = useState(false);
  const [activeTab, setActiveTab] = useState<string>('commodities');
  const [form] = Form.useForm();
  const [baselineForm] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const result = await loadUnits();
      setData(result);
    } catch (error) {
      message.error('Failed to load units configuration');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: UnitsData) => {
    try {
      await saveUnits(newData);
      setData(newData);
      message.success('Units configuration saved successfully');
    } catch (error) {
      message.error('Failed to save units configuration');
      console.error(error);
    }
  };

  // Commodity Unit handlers
  const handleAddCommodity = () => {
    setEditingCommodity(null);
    form.resetFields();
    form.setFieldsValue({
      unit: 'piece',
      durationType: 'consumable'
    });
    setIsModalVisible(true);
  };

  const handleEditCommodity = (commodityId: string) => {
    setEditingCommodity(commodityId);
    const unit = data?.commodityUnits[commodityId];
    form.setFieldsValue({
      id: commodityId,
      ...unit
    });
    setIsModalVisible(true);
  };

  const handleDeleteCommodity = (commodityId: string) => {
    if (!data) return;

    const newCommodityUnits = { ...data.commodityUnits };
    delete newCommodityUnits[commodityId];

    const newData: UnitsData = {
      ...data,
      commodityUnits: newCommodityUnits
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      const commodityId = editingCommodity || values.id;
      const { id, ...unitData } = values;

      // Clean up undefined values
      const cleanUnit: CommodityUnit = {
        unit: unitData.unit
      };
      if (unitData.caloriesPerUnit) cleanUnit.caloriesPerUnit = unitData.caloriesPerUnit;
      if (unitData.weightKg) cleanUnit.weightKg = unitData.weightKg;
      if (unitData.volumeLiters) cleanUnit.volumeLiters = unitData.volumeLiters;
      if (unitData.dailyNeedAmount) cleanUnit.dailyNeedAmount = unitData.dailyNeedAmount;
      if (unitData.durationType && unitData.durationType !== 'consumable') {
        cleanUnit.durationType = unitData.durationType;
      }
      if (unitData.durationDays) cleanUnit.durationDays = unitData.durationDays;
      if (unitData.description) cleanUnit.description = unitData.description;

      const newData: UnitsData = {
        ...data,
        commodityUnits: {
          ...data.commodityUnits,
          [commodityId]: cleanUnit
        }
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
      setEditingCommodity(null);
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Baseline handlers
  const handleEditBaseline = () => {
    if (!data) return;
    baselineForm.setFieldsValue(data.personDayBaseline);
    setIsBaselineModalVisible(true);
  };

  const handleBaselineOk = async () => {
    try {
      const values = await baselineForm.validateFields();
      if (!data) return;

      const newData: UnitsData = {
        ...data,
        personDayBaseline: values
      };

      await saveData(newData);
      setIsBaselineModalVisible(false);
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Filter commodities by search
  const commodityEntries = data?.commodityUnits
    ? Object.entries(data.commodityUnits).filter(([id]) =>
        id.toLowerCase().includes(searchText.toLowerCase())
      )
    : [];

  const commodityColumns = [
    {
      title: 'Commodity ID',
      dataIndex: 'id',
      key: 'id',
      width: 180,
      sorter: (a: any, b: any) => a.id.localeCompare(b.id)
    },
    {
      title: 'Unit',
      dataIndex: 'unit',
      key: 'unit',
      width: 100,
      render: (unit: string) => <Tag>{unit}</Tag>
    },
    {
      title: 'Calories',
      dataIndex: 'caloriesPerUnit',
      key: 'calories',
      width: 100,
      render: (cal: number | undefined) => cal ? `${cal} kcal` : '-'
    },
    {
      title: 'Daily Need',
      dataIndex: 'dailyNeedAmount',
      key: 'dailyNeed',
      width: 100,
      render: (amount: number | undefined, record: any) =>
        amount ? `${amount} ${record.unit}` : '-'
    },
    {
      title: 'Durability',
      dataIndex: 'durationType',
      key: 'durability',
      width: 120,
      render: (type: string | undefined, record: any) => {
        if (!type || type === 'consumable') {
          return <Tag color="blue">consumable</Tag>;
        } else if (type === 'durable') {
          return (
            <Tag color="green">
              durable {record.durationDays ? `(${record.durationDays}d)` : ''}
            </Tag>
          );
        } else if (type === 'permanent') {
          return <Tag color="purple">permanent</Tag>;
        }
        return '-';
      }
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 100,
      render: (_: any, record: any) => (
        <Space>
          <Button
            icon={<EditOutlined />}
            size="small"
            onClick={() => handleEditCommodity(record.id)}
          />
          <Popconfirm
            title="Delete this commodity unit?"
            onConfirm={() => handleDeleteCommodity(record.id)}
            okText="Yes"
            cancelText="No"
          >
            <Button icon={<DeleteOutlined />} size="small" danger />
          </Popconfirm>
        </Space>
      )
    }
  ];

  // Transform entries for table
  const tableData = commodityEntries.map(([id, unit]) => ({
    id,
    ...unit
  }));

  return (
    <div>
      <Card title="Units Configuration">
        <p style={{ marginBottom: 16, color: '#666' }}>
          Configure units, daily consumption baselines, and commodity-specific unit information.
        </p>

        <Tabs
          activeKey={activeTab}
          onChange={setActiveTab}
          items={[
            {
              key: 'baseline',
              label: 'Person-Day Baseline',
              children: (
                <div>
                  <p style={{ marginBottom: 16, color: '#666' }}>
                    The base daily requirements for an average adult. Used to calculate "feeds X people" and percentage of daily needs.
                  </p>

                  {data && (
                    <Card size="small" style={{ maxWidth: 600 }}>
                      <Row gutter={[24, 16]}>
                        <Col span={8}>
                          <Statistic
                            title="Daily Calories"
                            value={data.personDayBaseline.calories}
                            suffix="kcal"
                          />
                        </Col>
                        <Col span={8}>
                          <Statistic
                            title="Daily Water"
                            value={data.personDayBaseline.waterLiters}
                            suffix="L"
                          />
                        </Col>
                        <Col span={8}>
                          <Statistic
                            title="Daily Sleep"
                            value={data.personDayBaseline.sleepHours}
                            suffix="hrs"
                          />
                        </Col>
                      </Row>
                      {data.personDayBaseline.description && (
                        <p style={{ marginTop: 16, color: '#888' }}>
                          {data.personDayBaseline.description}
                        </p>
                      )}
                      <Button
                        type="primary"
                        icon={<SettingOutlined />}
                        onClick={handleEditBaseline}
                        style={{ marginTop: 16 }}
                      >
                        Edit Baseline
                      </Button>
                    </Card>
                  )}
                </div>
              )
            },
            {
              key: 'commodities',
              label: `Commodity Units (${commodityEntries.length})`,
              children: (
                <div>
                  <Space style={{ marginBottom: 16 }}>
                    <Input.Search
                      placeholder="Search commodities..."
                      value={searchText}
                      onChange={e => setSearchText(e.target.value)}
                      style={{ width: 300 }}
                      allowClear
                    />
                    <Button
                      type="primary"
                      icon={<PlusOutlined />}
                      onClick={handleAddCommodity}
                    >
                      Add Commodity
                    </Button>
                  </Space>

                  <Table
                    columns={commodityColumns}
                    dataSource={tableData}
                    rowKey="id"
                    loading={loading}
                    pagination={{ pageSize: 20, showSizeChanger: true }}
                    size="small"
                  />
                </div>
              )
            },
            {
              key: 'base-units',
              label: 'Base Unit Types',
              children: (
                <div>
                  <p style={{ marginBottom: 16, color: '#666' }}>
                    Fundamental unit types used throughout the system.
                  </p>

                  {data && (
                    <Descriptions bordered column={1} size="small">
                      {Object.entries(data.baseUnits).map(([type, config]) => (
                        <Descriptions.Item
                          key={type}
                          label={<strong style={{ textTransform: 'capitalize' }}>{type}</strong>}
                        >
                          <Space>
                            <span>Base: <Tag>{config.base}</Tag></span>
                            <span>Display: {config.display.map(d => <Tag key={d}>{d}</Tag>)}</span>
                            {config.conversions && (
                              <span>
                                Conversions: {Object.entries(config.conversions).map(([unit, factor]) => (
                                  <Tag key={unit}>{unit} = {factor}</Tag>
                                ))}
                              </span>
                            )}
                          </Space>
                        </Descriptions.Item>
                      ))}
                    </Descriptions>
                  )}
                </div>
              )
            }
          ]}
        />
      </Card>

      {/* Commodity Unit Modal */}
      <Modal
        title={editingCommodity ? `Edit: ${editingCommodity}` : 'Add Commodity Unit'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
          setEditingCommodity(null);
        }}
        width={600}
      >
        <Form form={form} layout="vertical">
          {!editingCommodity && (
            <Form.Item
              name="id"
              label="Commodity ID"
              rules={[
                { required: true, message: 'Please enter a commodity ID' },
                { pattern: /^[a-z_]+$/, message: 'ID should be lowercase with underscores only' }
              ]}
            >
              <Input placeholder="e.g., wheat, bread, water" />
            </Form.Item>
          )}

          <Form.Item
            name="unit"
            label="Unit"
            rules={[{ required: true, message: 'Please select a unit' }]}
          >
            <Select>
              <Option value="kg">kg (kilogram)</Option>
              <Option value="g">g (gram)</Option>
              <Option value="liter">liter</Option>
              <Option value="ml">ml (milliliter)</Option>
              <Option value="piece">piece</Option>
              <Option value="loaf">loaf</Option>
              <Option value="bottle">bottle</Option>
              <Option value="meter">meter</Option>
              <Option value="pair">pair</Option>
              <Option value="set">set</Option>
              <Option value="dose">dose</Option>
              <Option value="sheet">sheet</Option>
            </Select>
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="caloriesPerUnit"
                label="Calories per Unit"
              >
                <InputNumber min={0} style={{ width: '100%' }} placeholder="e.g., 1200" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="dailyNeedAmount"
                label="Daily Need Amount"
              >
                <InputNumber min={0} step={0.1} style={{ width: '100%' }} placeholder="e.g., 1.5" />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="weightKg"
                label="Weight (kg)"
              >
                <InputNumber min={0} step={0.1} style={{ width: '100%' }} placeholder="e.g., 0.5" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="volumeLiters"
                label="Volume (liters)"
              >
                <InputNumber min={0} step={0.1} style={{ width: '100%' }} placeholder="e.g., 0.75" />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="durationType"
                label="Durability Type"
              >
                <Select>
                  <Option value="consumable">Consumable (one-time use)</Option>
                  <Option value="durable">Durable (lasts multiple days)</Option>
                  <Option value="permanent">Permanent (lasts forever)</Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="durationDays"
                label="Duration (days)"
                extra="Only for durable items"
              >
                <InputNumber min={1} style={{ width: '100%' }} placeholder="e.g., 100" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} placeholder="Brief description of this commodity" />
          </Form.Item>
        </Form>
      </Modal>

      {/* Baseline Modal */}
      <Modal
        title="Edit Person-Day Baseline"
        open={isBaselineModalVisible}
        onOk={handleBaselineOk}
        onCancel={() => setIsBaselineModalVisible(false)}
        width={500}
      >
        <Form form={baselineForm} layout="vertical">
          <Form.Item
            name="calories"
            label="Daily Calories"
            rules={[{ required: true, message: 'Required' }]}
          >
            <InputNumber min={1000} max={5000} style={{ width: '100%' }} addonAfter="kcal" />
          </Form.Item>

          <Form.Item
            name="waterLiters"
            label="Daily Water"
            rules={[{ required: true, message: 'Required' }]}
          >
            <InputNumber min={0.5} max={10} step={0.5} style={{ width: '100%' }} addonAfter="liters" />
          </Form.Item>

          <Form.Item
            name="sleepHours"
            label="Daily Sleep"
            rules={[{ required: true, message: 'Required' }]}
          >
            <InputNumber min={4} max={12} style={{ width: '100%' }} addonAfter="hours" />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default UnitsManager;
