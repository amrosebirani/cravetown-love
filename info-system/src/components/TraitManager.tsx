import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, Select, Space, message, Popconfirm, Tag, Row, Col } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import type { CharacterTraitsData, CharacterTrait, DimensionDefinitions } from '../types';
import { loadCharacterTraits, saveCharacterTraits, loadDimensionDefinitions } from '../api';
import VectorEditor from './VectorEditor';
import VectorVisualization from './VectorVisualization';
import VectorHeatmap from './VectorHeatmap';

const { TextArea } = Input;

const TraitManager: React.FC = () => {
  const [data, setData] = useState<CharacterTraitsData | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDefinitions | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<CharacterTrait | null>(null);
  const [viewing, setViewing] = useState<CharacterTrait | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isViewModalVisible, setIsViewModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [traitsData, dimensionsData] = await Promise.all([
        loadCharacterTraits(),
        loadDimensionDefinitions()
      ]);
      setData(traitsData);
      setDimensions(dimensionsData);
    } catch (error) {
      message.error('Failed to load character traits');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: CharacterTraitsData) => {
    try {
      await saveCharacterTraits(newData);
      setData(newData);
      message.success('Character traits saved successfully');
    } catch (error) {
      message.error('Failed to save character traits');
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

    // Set default multipliers (all 1.0) with proper sizes
    form.setFieldsValue({
      cravingMultipliers: {
        coarse: new Array(requiredCoarseSize).fill(1.0),
        fine: new Array(requiredFineSize).fill(1.0),
      },
    });
    setIsModalVisible(true);
  };

  const handleEdit = (record: CharacterTrait) => {
    setEditing(record);
    // Get the required size from dimension definitions
    const maxDimensionIndex = dimensions ? Math.max(...dimensions.fineDimensions.map(d => d.index), 0) : 65;
    const requiredFineSize = maxDimensionIndex + 1;
    const requiredCoarseSize = dimensions ? dimensions.coarseDimensions.length : 10;

    // Ensure cravingMultipliers arrays are properly sized (extend, never trim)
    const existingFine = record.cravingMultipliers?.fine || [];
    const existingCoarse = record.cravingMultipliers?.coarse || [];

    // For multipliers, default is 1.0 (no change), not 0
    const cravingMultipliers = {
      coarse: [...existingCoarse, ...new Array(Math.max(0, requiredCoarseSize - existingCoarse.length)).fill(1.0)],
      fine: [...existingFine, ...new Array(Math.max(0, requiredFineSize - existingFine.length)).fill(1.0)],
    };

    form.setFieldsValue({
      ...record,
      cravingMultipliers,
    });
    setIsModalVisible(true);
  };

  const handleView = (record: CharacterTrait) => {
    setViewing(record);
    setIsViewModalVisible(true);
  };

  const handleDelete = (record: CharacterTrait) => {
    if (!data) return;

    const newData: CharacterTraitsData = {
      ...data,
      traits: data.traits.filter(t => t.id !== record.id),
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      let newTraits: CharacterTrait[];

      if (editing) {
        // Edit existing
        newTraits = data.traits.map(t =>
          t.id === editing.id ? values : t
        );
      } else {
        // Add new
        newTraits = [...data.traits, values];
      }

      const newData: CharacterTraitsData = {
        ...data,
        traits: newTraits,
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const getRarityColor = (rarity: string): string => {
    switch (rarity) {
      case 'common': return 'default';
      case 'uncommon': return 'blue';
      case 'rare': return 'purple';
      case 'very-rare': return 'gold';
      default: return 'default';
    }
  };

  // Table columns
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 200,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      width: 200,
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Rarity',
      dataIndex: 'rarity',
      key: 'rarity',
      width: 120,
      render: (rarity: string) => (
        <Tag color={getRarityColor(rarity)}>{rarity}</Tag>
      ),
      sorter: (a: CharacterTrait, b: CharacterTrait) => {
        const rarityOrder = ['common', 'uncommon', 'rare', 'very-rare'];
        return rarityOrder.indexOf(a.rarity) - rarityOrder.indexOf(b.rarity);
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      fixed: 'right' as const,
      render: (_: any, record: CharacterTrait) => (
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
            title="Delete this trait?"
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
            <span>Character Traits</span>
            <Tag color="blue">Version {data.version}</Tag>
          </Space>
        }
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            Add Character Trait
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={data.traits}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{ pageSize: 15 }}
        />
      </Card>

      {/* Edit/Add Modal */}
      <Modal
        title={editing ? 'Edit Character Trait' : 'Add Character Trait'}
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
                <Input placeholder="e.g., ambitious" disabled={!!editing} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="name"
                label="Name"
                rules={[{ required: true, message: 'Please input the name!' }]}
              >
                <Input placeholder="e.g., Ambitious" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="description"
            label="Description"
            rules={[{ required: true, message: 'Please input the description!' }]}
          >
            <TextArea rows={2} placeholder="Describe this trait..." />
          </Form.Item>

          <Form.Item
            name="rarity"
            label="Rarity"
            rules={[{ required: true, message: 'Please select the rarity!' }]}
          >
            <Select placeholder="Select rarity">
              <Select.Option value="common">Common</Select.Option>
              <Select.Option value="uncommon">Uncommon</Select.Option>
              <Select.Option value="rare">Rare</Select.Option>
              <Select.Option value="very-rare">Very Rare</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item
            name={['cravingMultipliers', 'fine']}
            label="Craving Multipliers (Fine)"
            help="Multipliers modify base craving values. 1.0 = no change, >1.0 = amplified, <1.0 = reduced"
          >
            <VectorEditor
              dimensions={dimensions.fineDimensions}
              min={0}
              max={3}
              step={0.1}
              title="Fine Craving Multipliers"
              showCoarseView={true}
              groupByParent={true}
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* View Modal */}
      <Modal
        title={
          <Space>
            <span>View Trait: {viewing?.name}</span>
            {viewing && <Tag color={getRarityColor(viewing.rarity)}>{viewing.rarity}</Tag>}
          </Space>
        }
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
                <Col span={24}>
                  <strong>Rarity:</strong> <Tag color={getRarityColor(viewing.rarity)}>{viewing.rarity}</Tag>
                </Col>
              </Row>
            </Card>

            <VectorVisualization
              key={`viz-${viewing.id}`}
              dimensions={dimensions.coarseDimensions}
              values={viewing.cravingMultipliers?.coarse ?? []}
              title={`Coarse Craving Multipliers (${dimensions.coarseDimensions.length}D)`}
              maxValue={3}
            />

            <VectorHeatmap
              key={`heatmap-${viewing.id}`}
              dimensions={dimensions.fineDimensions}
              values={viewing.cravingMultipliers?.fine ?? []}
              title={`Fine Craving Multipliers (${dimensions.fineDimensions.length}D)`}
              maxValue={3}
              colorScheme="purple"
            />
          </Space>
        )}
      </Modal>
    </div>
  );
};

export default TraitManager;
