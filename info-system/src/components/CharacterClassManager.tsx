import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Space, message, Popconfirm, Tag, Row, Col } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import type { CharacterClassesData, CharacterClass, DimensionDefinitions } from '../types';
import { loadCharacterClasses, saveCharacterClasses, loadDimensionDefinitions } from '../api';
import VectorEditor from './VectorEditor';
import VectorVisualization from './VectorVisualization';
import VectorHeatmap from './VectorHeatmap';

const { TextArea } = Input;

const CharacterClassManager: React.FC = () => {
  const [data, setData] = useState<CharacterClassesData | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDefinitions | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<CharacterClass | null>(null);
  const [viewing, setViewing] = useState<CharacterClass | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isViewModalVisible, setIsViewModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [classesData, dimensionsData] = await Promise.all([
        loadCharacterClasses(),
        loadDimensionDefinitions()
      ]);
      setData(classesData);
      setDimensions(dimensionsData);
    } catch (error) {
      message.error('Failed to load character classes');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: CharacterClassesData) => {
    try {
      await saveCharacterClasses(newData);
      setData(newData);
      message.success('Character classes saved successfully');
    } catch (error) {
      message.error('Failed to save character classes');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setEditing(null);
    form.resetFields();
    // Get the required size from dimension definitions
    const maxDimensionIndex = dimensions ? Math.max(...dimensions.fineDimensions.map(d => d.index), 0) : 65;
    const requiredFineSize = maxDimensionIndex + 1;
    const requiredCoarseSize = dimensions ? dimensions.coarseDimensions.length : 10;

    // Set default vectors (all zeros) with proper sizes
    form.setFieldsValue({
      baseCravingVector: {
        coarse: new Array(requiredCoarseSize).fill(0),
        fine: new Array(requiredFineSize).fill(0),
      },
      thresholds: {
        emigration: 50,
        riotContribution: 1.0,
        criticalSatisfaction: 30,
      },
      acceptedQualityTiers: [],
      rejectedQualityTiers: [],
    });
    setIsModalVisible(true);
  };

  const handleEdit = (record: CharacterClass) => {
    setEditing(record);
    // Get the required size from dimension definitions
    const maxDimensionIndex = dimensions ? Math.max(...dimensions.fineDimensions.map(d => d.index), 0) : 65;
    const requiredFineSize = maxDimensionIndex + 1;
    const requiredCoarseSize = dimensions ? dimensions.coarseDimensions.length : 10;

    // Ensure baseCravingVector arrays are properly sized
    const existingFine = record.baseCravingVector?.fine || [];
    const existingCoarse = record.baseCravingVector?.coarse || [];

    // Extend arrays to required size (never trim - preserve all data)
    const baseCravingVector = {
      coarse: [...existingCoarse, ...new Array(Math.max(0, requiredCoarseSize - existingCoarse.length)).fill(0)],
      fine: [...existingFine, ...new Array(Math.max(0, requiredFineSize - existingFine.length)).fill(0)],
    };

    form.setFieldsValue({
      ...record,
      baseCravingVector,
    });
    setIsModalVisible(true);
  };

  const handleView = (record: CharacterClass) => {
    setViewing(record);
    setIsViewModalVisible(true);
  };

  const handleDelete = (record: CharacterClass) => {
    if (!data) return;

    const newData: CharacterClassesData = {
      ...data,
      classes: data.classes.filter(c => c.id !== record.id),
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data || !dimensions) return;

      // Ensure baseCravingVector has both coarse and fine arrays
      if (values.baseCravingVector) {
        // Always recalculate coarse from fine using dimension definitions
        const fine = values.baseCravingVector.fine || [];
        const coarseCount = dimensions.coarseDimensions.length;
        const coarse = new Array(coarseCount).fill(0);
        const coarseCounts = new Array(coarseCount).fill(0);

        // Build coarse index lookup from dimension definitions
        const coarseIdToIndex: Record<string, number> = {};
        dimensions.coarseDimensions.forEach(cd => {
          coarseIdToIndex[cd.id] = cd.index;
        });

        // Aggregate fine to coarse using dimension definitions
        dimensions.fineDimensions.forEach(fineDim => {
          const fineValue = fine[fineDim.index] || 0;
          const coarseIdx = coarseIdToIndex[fineDim.parentCoarse];
          if (coarseIdx !== undefined) {
            coarse[coarseIdx] += fineValue;
            coarseCounts[coarseIdx] += 1;
          }
        });

        // Calculate averages
        for (let i = 0; i < coarseCount; i++) {
          if (coarseCounts[i] > 0) {
            coarse[i] = coarse[i] / coarseCounts[i];
          }
        }

        values.baseCravingVector.coarse = coarse;
      }

      let newClasses: CharacterClass[];

      if (editing) {
        // Edit existing
        newClasses = data.classes.map(c =>
          c.id === editing.id ? values : c
        );
      } else {
        // Add new
        newClasses = [...data.classes, values];
      }

      const newData: CharacterClassesData = {
        ...data,
        classes: newClasses,
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Table columns
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 150,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      width: 150,
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Allocation Priority',
      dataIndex: 'allocationPriority',
      key: 'allocationPriority',
      width: 150,
      align: 'center' as const,
      sorter: (a: CharacterClass, b: CharacterClass) => a.allocationPriority - b.allocationPriority,
    },
    {
      title: 'Base Income',
      dataIndex: 'baseIncome',
      key: 'baseIncome',
      width: 120,
      align: 'center' as const,
    },
    {
      title: 'Emigration Threshold',
      dataIndex: ['thresholds', 'emigration'],
      key: 'emigration',
      width: 150,
      align: 'center' as const,
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      fixed: 'right' as const,
      render: (_: any, record: CharacterClass) => (
        <Space>
          <Button
            type="link"
            icon={<EyeOutlined />}
            onClick={() => handleView(record)}
          />
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          />
          <Popconfirm
            title="Delete this character class?"
            onConfirm={() => handleDelete(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="link" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  if (!data || !dimensions) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <span>Character Classes</span>
            <Tag color="blue">Version {data.version}</Tag>
          </Space>
        }
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            Add Character Class
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={data.classes}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1200 }}
          pagination={{ pageSize: 10 }}
        />
      </Card>

      {/* Edit/Add Modal */}
      <Modal
        title={editing ? 'Edit Character Class' : 'Add Character Class'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={1200}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="id"
                label="ID"
                rules={[{ required: true, message: 'Please input the ID!' }]}
              >
                <Input placeholder="e.g., elite" disabled={!!editing} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="name"
                label="Name"
                rules={[{ required: true, message: 'Please input the name!' }]}
              >
                <Input placeholder="e.g., Elite" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="description"
            label="Description"
            rules={[{ required: true, message: 'Please input the description!' }]}
          >
            <TextArea rows={2} placeholder="Describe this character class..." />
          </Form.Item>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item
                name="allocationPriority"
                label="Allocation Priority"
                rules={[{ required: true, message: 'Please input the priority!' }]}
              >
                <InputNumber min={1} max={10} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item
                name="baseIncome"
                label="Base Income"
                rules={[{ required: true, message: 'Please input the base income!' }]}
              >
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item
                name={['thresholds', 'emigration']}
                label="Emigration Threshold"
                rules={[{ required: true }]}
              >
                <InputNumber min={0} max={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item
                name={['thresholds', 'riotContribution']}
                label="Riot Contribution"
                rules={[{ required: true }]}
              >
                <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item
                name={['thresholds', 'criticalSatisfaction']}
                label="Critical Satisfaction"
                rules={[{ required: true }]}
              >
                <InputNumber min={0} max={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="acceptedQualityTiers"
                label="Accepted Quality Tiers"
              >
                <Select mode="multiple" placeholder="Select accepted tiers">
                  <Select.Option value="poor">Poor</Select.Option>
                  <Select.Option value="basic">Basic</Select.Option>
                  <Select.Option value="good">Good</Select.Option>
                  <Select.Option value="luxury">Luxury</Select.Option>
                  <Select.Option value="masterwork">Masterwork</Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="rejectedQualityTiers"
                label="Rejected Quality Tiers"
              >
                <Select mode="multiple" placeholder="Select rejected tiers">
                  <Select.Option value="poor">Poor</Select.Option>
                  <Select.Option value="basic">Basic</Select.Option>
                  <Select.Option value="good">Good</Select.Option>
                  <Select.Option value="luxury">Luxury</Select.Option>
                  <Select.Option value="masterwork">Masterwork</Select.Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name={['baseCravingVector', 'fine']}
            label="Base Craving Vector (Fine - 50D)"
          >
            <VectorEditor
              dimensions={dimensions.fineDimensions}
              min={0}
              max={10}
              step={0.1}
              title="Fine Craving Vector (50D)"
              showCoarseView={true}
              groupByParent={true}
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* View Modal */}
      <Modal
        title={`View Character Class: ${viewing?.name}`}
        open={isViewModalVisible}
        onCancel={() => setIsViewModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setIsViewModalVisible(false)}>
            Close
          </Button>
        ]}
        width={1400}
      >
        {viewing && (
          <Space direction="vertical" style={{ width: '100%' }} size="large">
            <Card size="small">
              <Row gutter={[16, 16]}>
                <Col span={12}>
                  <strong>ID:</strong> {viewing.id}
                </Col>
                <Col span={12}>
                  <strong>Name:</strong> {viewing.name}
                </Col>
                <Col span={24}>
                  <strong>Description:</strong> {viewing.description}
                </Col>
                <Col span={8}>
                  <strong>Allocation Priority:</strong> {viewing.allocationPriority}
                </Col>
                <Col span={8}>
                  <strong>Base Income:</strong> {viewing.baseIncome}
                </Col>
                <Col span={8}>
                  <strong>Emigration Threshold:</strong> {viewing.thresholds.emigration}
                </Col>
                <Col span={12}>
                  <strong>Accepted Quality Tiers:</strong>{' '}
                  {viewing.acceptedQualityTiers.map(t => (
                    <Tag key={t} color="green">{t}</Tag>
                  ))}
                </Col>
                <Col span={12}>
                  <strong>Rejected Quality Tiers:</strong>{' '}
                  {viewing.rejectedQualityTiers.map(t => (
                    <Tag key={t} color="red">{t}</Tag>
                  ))}
                </Col>
              </Row>
            </Card>

            <VectorVisualization
              dimensions={dimensions.coarseDimensions}
              values={viewing.baseCravingVector.coarse}
              title="Coarse Craving Profile (9D)"
              maxValue={10}
            />

            <VectorHeatmap
              dimensions={dimensions.fineDimensions}
              values={viewing.baseCravingVector.fine}
              title="Fine Craving Vector (50D)"
              maxValue={10}
              colorScheme="blue"
            />
          </Space>
        )}
      </Modal>
    </div>
  );
};

export default CharacterClassManager;
