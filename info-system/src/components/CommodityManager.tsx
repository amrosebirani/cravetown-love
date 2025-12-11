import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input, Select, Tag } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { Commodity, CommoditiesData, CommodityCategory, QualityTierDefinition, QualityTier } from '../types';
import { loadCommodities, saveCommodities, loadCommodityCategories, loadQualityTiers } from '../api';

// Quality tier colors for display
const QUALITY_COLORS: Record<QualityTier, string> = {
  poor: '#8b6914',
  basic: '#6b6b6b',
  good: '#2d862d',
  luxury: '#cc9900',
  masterwork: '#8b2d8b'
};

const CommodityManager = () => {
  const [commodities, setCommodities] = useState<Commodity[]>([]);
  const [categories, setCategories] = useState<CommodityCategory[]>([]);
  const [qualityTiers, setQualityTiers] = useState<QualityTierDefinition[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingCommodity, setEditingCommodity] = useState<Commodity | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadCommoditiesList();
    loadCategoriesList();
    loadQualityTiersList();
  }, []);

  const loadCommoditiesList = async () => {
    setLoading(true);
    try {
      const data = await loadCommodities();
      setCommodities(data.commodities);
      messageApi.success('Commodities loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load commodities: ${error}`);
      console.error('Failed to load commodities:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadCategoriesList = async () => {
    try {
      const data = await loadCommodityCategories();
      setCategories(data.categories);
    } catch (error) {
      messageApi.error(`Failed to load categories: ${error}`);
      console.error('Failed to load categories:', error);
    }
  };

  const loadQualityTiersList = async () => {
    try {
      const data = await loadQualityTiers();
      setQualityTiers(data.tiers || []);
    } catch (error) {
      // Quality tiers file might not exist, use defaults
      console.warn('Could not load quality tiers, using defaults:', error);
      setQualityTiers([
        { id: 'poor', name: 'Poor', description: 'Low quality', order: 0, defaultMultiplier: 0.6, valueMultiplier: 0.4, color: [0.6, 0.4, 0.3] },
        { id: 'basic', name: 'Basic', description: 'Standard quality', order: 1, defaultMultiplier: 1.0, valueMultiplier: 1.0, color: [0.7, 0.7, 0.7] },
        { id: 'good', name: 'Good', description: 'Above average', order: 2, defaultMultiplier: 1.3, valueMultiplier: 1.8, color: [0.3, 0.6, 0.3] },
        { id: 'luxury', name: 'Luxury', description: 'High quality', order: 3, defaultMultiplier: 1.8, valueMultiplier: 3.0, color: [0.8, 0.6, 0.2] },
        { id: 'masterwork', name: 'Masterwork', description: 'Exceptional', order: 4, defaultMultiplier: 2.5, valueMultiplier: 5.0, color: [0.6, 0.3, 0.8] },
      ]);
    }
  };

  const saveCommoditiesList = async (updatedCommodities: Commodity[]) => {
    try {
      const data: CommoditiesData = { commodities: updatedCommodities };
      await saveCommodities(data);
      setCommodities(updatedCommodities);
      messageApi.success('Commodities saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save commodities: ${error}`);
      console.error('Failed to save commodities:', error);
    }
  };

  const handleAddCommodity = () => {
    const newCommodity: Commodity = {
      id: 'new_commodity',
      name: 'New Commodity',
      category: 'Uncategorized',
      description: '',
      quality: 'basic'
    };
    setEditingCommodity(newCommodity);
    form.setFieldsValue(newCommodity);
    setEditorVisible(true);
  };

  const handleEditCommodity = (commodity: Commodity) => {
    setEditingCommodity({ ...commodity });
    form.setFieldsValue(commodity);
    setEditorVisible(true);
  };

  const handleSaveCommodity = () => {
    form.validateFields().then((values) => {
      const isNew = !commodities.find(c => c.id === editingCommodity?.id);

      let updatedCommodities: Commodity[];
      if (isNew) {
        updatedCommodities = [...commodities, values];
      } else {
        updatedCommodities = commodities.map(c =>
          c.id === editingCommodity?.id ? values : c
        );
      }

      saveCommoditiesList(updatedCommodities);
      setEditorVisible(false);
      setEditingCommodity(null);
      form.resetFields();
    });
  };

  const handleDeleteCommodity = async (id: string) => {
    const updatedCommodities = commodities.filter(c => c.id !== id);
    await saveCommoditiesList(updatedCommodities);
  };

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
      width: 200,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 150,
      render: (categoryId: string) => {
        const category = categories.find(c => c.id === categoryId);
        if (category) {
          return (
            <Tag color={category.color}>
              {category.name}
            </Tag>
          );
        }
        return categoryId;
      },
    },
    {
      title: 'Quality',
      dataIndex: 'quality',
      key: 'quality',
      width: 120,
      render: (quality: QualityTier | undefined) => {
        const tier = qualityTiers.find(t => t.id === quality) ||
          qualityTiers.find(t => t.id === 'basic');
        const color = QUALITY_COLORS[quality || 'basic'] || QUALITY_COLORS.basic;
        return (
          <Tag color={color}>
            {tier?.name || quality || 'Basic'}
          </Tag>
        );
      },
      filters: qualityTiers.map(tier => ({ text: tier.name, value: tier.id })),
      onFilter: (value: React.Key | boolean, record: Commodity) =>
        record.quality === value || (!record.quality && value === 'basic'),
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: unknown, record: Commodity) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditCommodity(record)}
          />
          <Popconfirm
            title="Delete this commodity?"
            description="This action cannot be undone."
            onConfirm={() => handleDeleteCommodity(record.id)}
            okText="Yes"
            cancelText="No"
          >
            <Button
              type="link"
              danger
              icon={<DeleteOutlined />}
            />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // Filter commodities based on search text
  const filteredCommodities = commodities.filter(commodity => {
    const searchLower = searchText.toLowerCase();
    return (
      commodity.id.toLowerCase().includes(searchLower) ||
      commodity.name.toLowerCase().includes(searchLower) ||
      commodity.category.toLowerCase().includes(searchLower) ||
      (commodity.description && commodity.description.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Commodities</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddCommodity}
          >
            Add Commodity
          </Button>
        </div>

        <Input
          placeholder="Search commodities by ID, name, category, or description..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredCommodities}
          rowKey="id"
          loading={loading}
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} commodities${searchText ? ` (filtered from ${commodities.length})` : ''}`,
          }}
        />

        <Modal
          title={editingCommodity && commodities.find(c => c.id === editingCommodity.id) ? 'Edit Commodity' : 'Add Commodity'}
          open={editorVisible}
          onOk={handleSaveCommodity}
          onCancel={() => {
            setEditorVisible(false);
            setEditingCommodity(null);
            form.resetFields();
          }}
          okText="Save"
        >
          <Form
            form={form}
            layout="vertical"
            style={{ marginTop: '24px' }}
          >
            <Form.Item
              label="Commodity ID"
              name="id"
              rules={[{ required: true, message: 'ID is required' }]}
            >
              <Input />
            </Form.Item>

            <Form.Item
              label="Name"
              name="name"
              rules={[{ required: true, message: 'Name is required' }]}
            >
              <Input />
            </Form.Item>

            <Form.Item
              label="Category"
              name="category"
              rules={[{ required: true, message: 'Category is required' }]}
            >
              <Select
                placeholder="Select a category"
                showSearch
                optionFilterProp="children"
              >
                {categories.map(category => (
                  <Select.Option key={category.id} value={category.id}>
                    <Space>
                      <div style={{
                        width: 12,
                        height: 12,
                        backgroundColor: category.color,
                        border: '1px solid #ddd',
                        borderRadius: 2,
                        display: 'inline-block'
                      }} />
                      {category.name}
                    </Space>
                  </Select.Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              label="Quality"
              name="quality"
              initialValue="basic"
            >
              <Select placeholder="Select quality tier">
                {qualityTiers.sort((a, b) => a.order - b.order).map(tier => (
                  <Select.Option key={tier.id} value={tier.id}>
                    <Space>
                      <div style={{
                        width: 12,
                        height: 12,
                        backgroundColor: QUALITY_COLORS[tier.id as QualityTier] || '#888',
                        border: '1px solid #ddd',
                        borderRadius: 2,
                        display: 'inline-block'
                      }} />
                      {tier.name}
                    </Space>
                  </Select.Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              label="Description"
              name="description"
            >
              <Input.TextArea rows={3} />
            </Form.Item>
          </Form>
        </Modal>
      </div>
    </>
  );
};

export default CommodityManager;
