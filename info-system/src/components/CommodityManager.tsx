import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { Commodity, CommoditiesData } from '../types';
import { loadCommodities, saveCommodities } from '../api';

const CommodityManager = () => {
  const [commodities, setCommodities] = useState<Commodity[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingCommodity, setEditingCommodity] = useState<Commodity | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadCommoditiesList();
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
      description: ''
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
              <Input />
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
