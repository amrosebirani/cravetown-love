import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Tag, Space, Tabs, message, Popconfirm } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import type { DimensionDefinitions, CoarseDimension, FineDimension } from '../types';
import { loadDimensionDefinitions, saveDimensionDefinitions } from '../api';

const { TextArea } = Input;

const DimensionManager: React.FC = () => {
  const [data, setData] = useState<DimensionDefinitions | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingCoarse, setEditingCoarse] = useState<CoarseDimension | null>(null);
  const [editingFine, setEditingFine] = useState<FineDimension | null>(null);
  const [isCoarseModalVisible, setIsCoarseModalVisible] = useState(false);
  const [isFineModalVisible, setIsFineModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const result = await loadDimensionDefinitions();
      setData(result);
    } catch (error) {
      message.error('Failed to load dimension definitions');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: DimensionDefinitions) => {
    try {
      await saveDimensionDefinitions(newData);
      setData(newData);
      message.success('Dimension definitions saved successfully');
    } catch (error) {
      message.error('Failed to save dimension definitions');
      console.error(error);
    }
  };

  // Coarse Dimension handlers
  const handleAddCoarse = () => {
    setEditingCoarse(null);
    form.resetFields();
    setIsCoarseModalVisible(true);
  };

  const handleEditCoarse = (record: CoarseDimension) => {
    setEditingCoarse(record);
    form.setFieldsValue(record);
    setIsCoarseModalVisible(true);
  };

  const handleDeleteCoarse = (record: CoarseDimension) => {
    if (!data) return;

    const newData: DimensionDefinitions = {
      ...data,
      coarseDimensions: data.coarseDimensions.filter(d => d.id !== record.id),
      dimensionCount: {
        ...data.dimensionCount,
        coarse: data.dimensionCount.coarse - 1
      }
    };

    saveData(newData);
  };

  const handleCoarseModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      let newCoarseDimensions: CoarseDimension[];

      if (editingCoarse) {
        // Edit existing
        newCoarseDimensions = data.coarseDimensions.map(d =>
          d.id === editingCoarse.id ? { ...values, index: d.index } : d
        );
      } else {
        // Add new
        const maxIndex = Math.max(...data.coarseDimensions.map(d => d.index), -1);
        newCoarseDimensions = [
          ...data.coarseDimensions,
          { ...values, index: maxIndex + 1 }
        ];
      }

      const newData: DimensionDefinitions = {
        ...data,
        coarseDimensions: newCoarseDimensions,
        dimensionCount: {
          ...data.dimensionCount,
          coarse: newCoarseDimensions.length
        }
      };

      await saveData(newData);
      setIsCoarseModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Fine Dimension handlers
  const handleAddFine = () => {
    setEditingFine(null);
    form.resetFields();
    setIsFineModalVisible(true);
  };

  const handleEditFine = (record: FineDimension) => {
    setEditingFine(record);
    form.setFieldsValue({
      ...record,
      tags: record.tags.join(', ')
    });
    setIsFineModalVisible(true);
  };

  const handleDeleteFine = (record: FineDimension) => {
    if (!data) return;

    const newData: DimensionDefinitions = {
      ...data,
      fineDimensions: data.fineDimensions.filter(d => d.id !== record.id),
      dimensionCount: {
        ...data.dimensionCount,
        fine: data.dimensionCount.fine - 1
      }
    };

    saveData(newData);
  };

  const handleFineModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      // Parse tags
      const tags = typeof values.tags === 'string'
        ? values.tags.split(',').map((t: string) => t.trim()).filter((t: string) => t)
        : values.tags;

      let newFineDimensions: FineDimension[];

      if (editingFine) {
        // Edit existing
        newFineDimensions = data.fineDimensions.map(d =>
          d.id === editingFine.id
            ? { ...values, tags, index: d.index }
            : d
        );
      } else {
        // Add new
        const maxIndex = Math.max(...data.fineDimensions.map(d => d.index), -1);
        newFineDimensions = [
          ...data.fineDimensions,
          { ...values, tags, index: maxIndex + 1 }
        ];
      }

      const newData: DimensionDefinitions = {
        ...data,
        fineDimensions: newFineDimensions,
        dimensionCount: {
          ...data.dimensionCount,
          fine: newFineDimensions.length
        }
      };

      await saveData(newData);
      setIsFineModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Table columns
  const coarseColumns = [
    {
      title: 'Index',
      dataIndex: 'index',
      key: 'index',
      width: 80,
      sorter: (a: CoarseDimension, b: CoarseDimension) => a.index - b.index,
    },
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
      title: 'Tier',
      dataIndex: 'tier',
      key: 'tier',
      width: 120,
      render: (tier: string) => <Tag>{tier}</Tag>,
    },
    {
      title: 'Critical Threshold',
      dataIndex: 'criticalThreshold',
      key: 'criticalThreshold',
      width: 130,
      align: 'center' as const,
    },
    {
      title: 'Emigration Weight',
      dataIndex: 'emigrationWeight',
      key: 'emigrationWeight',
      width: 150,
      align: 'center' as const,
    },
    {
      title: 'Productivity Impact',
      dataIndex: 'productivityImpact',
      key: 'productivityImpact',
      width: 150,
      align: 'center' as const,
    },
    {
      title: 'Decay Rate',
      dataIndex: 'decayRate',
      key: 'decayRate',
      width: 120,
      align: 'center' as const,
      render: (rate: number | undefined) => rate !== undefined ? rate.toFixed(3) : '-',
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: any, record: CoarseDimension) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditCoarse(record)}
          />
          <Popconfirm
            title="Delete this coarse dimension?"
            onConfirm={() => handleDeleteCoarse(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="link" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const fineColumns = [
    {
      title: 'Index',
      dataIndex: 'index',
      key: 'index',
      width: 80,
      sorter: (a: FineDimension, b: FineDimension) => a.index - b.index,
    },
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
      width: 150,
    },
    {
      title: 'Parent Coarse',
      dataIndex: 'parentCoarse',
      key: 'parentCoarse',
      width: 150,
      render: (parentCoarse: string) => <Tag color="blue">{parentCoarse}</Tag>,
    },
    {
      title: 'Tags',
      dataIndex: 'tags',
      key: 'tags',
      render: (tags: string[]) => (
        <>
          {tags.map(tag => (
            <Tag key={tag} color="green">{tag}</Tag>
          ))}
        </>
      ),
    },
    {
      title: 'Aggregation Weight',
      dataIndex: 'aggregationWeight',
      key: 'aggregationWeight',
      width: 150,
      align: 'center' as const,
    },
    {
      title: 'Decay Rate',
      dataIndex: 'decayRate',
      key: 'decayRate',
      width: 120,
      align: 'center' as const,
      render: (rate: number | undefined) => rate !== undefined ? rate.toFixed(3) : '-',
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: any, record: FineDimension) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditFine(record)}
          />
          <Popconfirm
            title="Delete this fine dimension?"
            onConfirm={() => handleDeleteFine(record)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="link" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  if (!data) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <span>Dimension Definitions</span>
            <Tag color="blue">Version {data.version}</Tag>
          </Space>
        }
        extra={
          <Space>
            <span>Coarse: {data.dimensionCount.coarse}</span>
            <span>Fine: {data.dimensionCount.fine}</span>
          </Space>
        }
      >
        <Tabs
          defaultActiveKey="coarse"
          items={[
            {
              key: 'coarse',
              label: 'Coarse Dimensions (9D)',
              children: (
                <>
                  <Space style={{ marginBottom: 16 }}>
                    <Button
                      type="primary"
                      icon={<PlusOutlined />}
                      onClick={handleAddCoarse}
                    >
                      Add Coarse Dimension
                    </Button>
                  </Space>
                  <Table
                    columns={coarseColumns}
                    dataSource={data.coarseDimensions}
                    rowKey="id"
                    loading={loading}
                    scroll={{ x: 1400 }}
                    pagination={{ pageSize: 20 }}
                  />
                </>
              ),
            },
            {
              key: 'fine',
              label: 'Fine Dimensions (50D)',
              children: (
                <>
                  <Space style={{ marginBottom: 16 }}>
                    <Button
                      type="primary"
                      icon={<PlusOutlined />}
                      onClick={handleAddFine}
                    >
                      Add Fine Dimension
                    </Button>
                  </Space>
                  <Table
                    columns={fineColumns}
                    dataSource={data.fineDimensions}
                    rowKey="id"
                    loading={loading}
                    scroll={{ x: 1200 }}
                    pagination={{ pageSize: 20 }}
                  />
                </>
              ),
            },
          ]}
        />
      </Card>

      {/* Coarse Dimension Modal */}
      <Modal
        title={editingCoarse ? 'Edit Coarse Dimension' : 'Add Coarse Dimension'}
        open={isCoarseModalVisible}
        onOk={handleCoarseModalOk}
        onCancel={() => {
          setIsCoarseModalVisible(false);
          form.resetFields();
        }}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="id"
            label="ID"
            rules={[{ required: true, message: 'Please input the ID!' }]}
          >
            <Input placeholder="e.g., biological" disabled={!!editingCoarse} />
          </Form.Item>

          <Form.Item
            name="name"
            label="Name"
            rules={[{ required: true, message: 'Please input the name!' }]}
          >
            <Input placeholder="e.g., Biological" />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
            rules={[{ required: true, message: 'Please input the description!' }]}
          >
            <TextArea rows={3} placeholder="Describe this dimension..." />
          </Form.Item>

          <Form.Item
            name="tier"
            label="Tier"
            rules={[{ required: true, message: 'Please select the tier!' }]}
          >
            <Select>
              <Select.Option value="survival">Survival</Select.Option>
              <Select.Option value="comfort">Comfort</Select.Option>
              <Select.Option value="social">Social</Select.Option>
              <Select.Option value="aspirational">Aspirational</Select.Option>
              <Select.Option value="vice">Vice</Select.Option>
            </Select>
          </Form.Item>

          <Form.Item
            name="criticalThreshold"
            label="Critical Threshold"
            rules={[{ required: true, message: 'Please input the threshold!' }]}
          >
            <InputNumber min={0} max={100} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="emigrationWeight"
            label="Emigration Weight"
            rules={[{ required: true, message: 'Please input the weight!' }]}
          >
            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="productivityImpact"
            label="Productivity Impact"
            rules={[{ required: true, message: 'Please input the impact!' }]}
          >
            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="decayRate"
            label="Decay Rate"
            help="Rate at which satisfaction decreases per time unit (e.g., 0.01 = 1% per day)"
          >
            <InputNumber min={0} max={1} step={0.001} style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>

      {/* Fine Dimension Modal */}
      <Modal
        title={editingFine ? 'Edit Fine Dimension' : 'Add Fine Dimension'}
        open={isFineModalVisible}
        onOk={handleFineModalOk}
        onCancel={() => {
          setIsFineModalVisible(false);
          form.resetFields();
        }}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="id"
            label="ID"
            rules={[{ required: true, message: 'Please input the ID!' }]}
          >
            <Input placeholder="e.g., biological_nutrition_grain" disabled={!!editingFine} />
          </Form.Item>

          <Form.Item
            name="name"
            label="Name"
            rules={[{ required: true, message: 'Please input the name!' }]}
          >
            <Input placeholder="e.g., Grain" />
          </Form.Item>

          <Form.Item
            name="parentCoarse"
            label="Parent Coarse Dimension"
            rules={[{ required: true, message: 'Please select the parent!' }]}
          >
            <Select>
              {data.coarseDimensions.map(d => (
                <Select.Option key={d.id} value={d.id}>
                  {d.name}
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="tags"
            label="Tags (comma-separated)"
            rules={[{ required: true, message: 'Please input tags!' }]}
          >
            <Input placeholder="e.g., nutrition, grain, staple" />
          </Form.Item>

          <Form.Item
            name="aggregationWeight"
            label="Aggregation Weight"
            rules={[{ required: true, message: 'Please input the weight!' }]}
          >
            <InputNumber min={0} max={1} step={0.05} style={{ width: '100%' }} />
          </Form.Item>

          <Form.Item
            name="decayRate"
            label="Decay Rate"
            help="Rate at which satisfaction decreases per time unit (e.g., 0.01 = 1% per day)"
          >
            <InputNumber min={0} max={1} step={0.001} style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default DimensionManager;
