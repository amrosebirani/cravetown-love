import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, Select, Space, message, Popconfirm, Tag } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons';
import type { CommodityCategoriesData, CommodityCategory } from '../types';
import { loadCommodityCategories, saveCommodityCategories } from '../api';

const { TextArea } = Input;

const CommodityCategoryManager: React.FC = () => {
  const [data, setData] = useState<CommodityCategoriesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<CommodityCategory | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const categoriesData = await loadCommodityCategories();
      setData(categoriesData);
    } catch (error) {
      message.error('Failed to load commodity categories');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: CommodityCategoriesData) => {
    try {
      await saveCommodityCategories(newData);
      setData(newData);
      message.success('Commodity categories saved successfully');
    } catch (error) {
      message.error('Failed to save commodity categories');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setEditing(null);
    form.resetFields();
    setIsModalVisible(true);
  };

  const handleEdit = (record: CommodityCategory) => {
    setEditing(record);
    form.setFieldsValue(record);
    setIsModalVisible(true);
  };

  const handleDelete = (record: CommodityCategory) => {
    if (!data) return;

    const newData: CommodityCategoriesData = {
      ...data,
      categories: data.categories.filter(c => c.id !== record.id),
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      let newCategories: CommodityCategory[];

      if (editing) {
        // Edit existing
        newCategories = data.categories.map(c =>
          c.id === editing.id ? values : c
        );
      } else {
        // Add new
        newCategories = [...data.categories, values];
      }

      const newData: CommodityCategoriesData = {
        ...data,
        categories: newCategories,
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
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
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Color',
      dataIndex: 'color',
      key: 'color',
      width: 100,
      render: (color: string) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{ width: 20, height: 20, backgroundColor: color, border: '1px solid #ddd', borderRadius: 4 }} />
          <span style={{ fontSize: 11, color: '#666' }}>{color}</span>
        </div>
      ),
    },
    {
      title: 'Tags',
      dataIndex: 'tags',
      key: 'tags',
      width: 250,
      render: (tags: string[]) => (
        <>
          {tags.map(tag => (
            <Tag key={tag} color="blue">{tag}</Tag>
          ))}
        </>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: any, record: CommodityCategory) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          />
          <Popconfirm
            title="Delete this category?"
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

  if (!data) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={`Commodity Categories (${data.categories.length})`}
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            Add Category
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={data.categories}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{ pageSize: 20 }}
        />
      </Card>

      <Modal
        title={editing ? 'Edit Commodity Category' : 'Add Commodity Category'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={700}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="id"
            label="ID"
            rules={[{ required: true, message: 'Please input the ID!' }]}
          >
            <Input placeholder="e.g., food_grain" disabled={!!editing} />
          </Form.Item>

          <Form.Item
            name="name"
            label="Name"
            rules={[{ required: true, message: 'Please input the name!' }]}
          >
            <Input placeholder="e.g., Grain Foods" />
          </Form.Item>

          <Form.Item
            name="description"
            label="Description"
          >
            <TextArea rows={2} placeholder="Description of this category..." />
          </Form.Item>

          <Form.Item
            name="color"
            label="Color (Hex)"
            rules={[{ required: true, message: 'Please input the color!' }]}
          >
            <Input placeholder="#f4a460" />
          </Form.Item>

          <Form.Item
            name="tags"
            label="Tags"
            rules={[{ required: true, message: 'Please add at least one tag!' }]}
          >
            <Select mode="tags" placeholder="Add tags (press Enter to add)" />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default CommodityCategoryManager;
