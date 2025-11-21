import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { WorkCategory, WorkCategoriesData } from '../types';
import { loadWorkCategories, saveWorkCategories } from '../api';

const WorkCategoryManager = () => {
  const [workCategories, setWorkCategories] = useState<WorkCategory[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingCategory, setEditingCategory] = useState<WorkCategory | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadWorkCategoriesList();
  }, []);

  const loadWorkCategoriesList = async () => {
    setLoading(true);
    try {
      const data = await loadWorkCategories();
      setWorkCategories(data.workCategories);
      messageApi.success('Work categories loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load work categories: ${error}`);
      console.error('Failed to load work categories:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveWorkCategoriesList = async (updatedCategories: WorkCategory[]) => {
    try {
      const data: WorkCategoriesData = { workCategories: updatedCategories };
      await saveWorkCategories(data);
      setWorkCategories(updatedCategories);
      messageApi.success('Work categories saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save work categories: ${error}`);
      console.error('Failed to save work categories:', error);
    }
  };

  const handleAddCategory = () => {
    const newCategory: WorkCategory = {
      id: 'new_category',
      name: 'New Category',
      description: ''
    };
    setEditingCategory(newCategory);
    form.setFieldsValue(newCategory);
    setEditorVisible(true);
  };

  const handleEditCategory = (category: WorkCategory) => {
    setEditingCategory({ ...category });
    form.setFieldsValue(category);
    setEditorVisible(true);
  };

  const handleSaveCategory = () => {
    form.validateFields().then((values) => {
      const isNew = !workCategories.find(c => c.id === editingCategory?.id);

      let updatedCategories: WorkCategory[];
      if (isNew) {
        updatedCategories = [...workCategories, values];
      } else {
        updatedCategories = workCategories.map(c =>
          c.id === editingCategory?.id ? values : c
        );
      }

      saveWorkCategoriesList(updatedCategories);
      setEditorVisible(false);
      setEditingCategory(null);
      form.resetFields();
    });
  };

  const handleDeleteCategory = async (id: string) => {
    const updatedCategories = workCategories.filter(c => c.id !== id);
    await saveWorkCategoriesList(updatedCategories);
  };

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
      width: 250,
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
      render: (_: unknown, record: WorkCategory) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditCategory(record)}
          />
          <Popconfirm
            title="Delete this work category?"
            description="This may affect worker types and building types that use this category."
            onConfirm={() => handleDeleteCategory(record.id)}
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

  // Filter work categories based on search text
  const filteredCategories = workCategories.filter(category => {
    const searchLower = searchText.toLowerCase();
    return (
      category.id.toLowerCase().includes(searchLower) ||
      category.name.toLowerCase().includes(searchLower) ||
      (category.description && category.description.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Work Categories</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddCategory}
          >
            Add Work Category
          </Button>
        </div>

        <Input
          placeholder="Search work categories by ID, name, or description..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredCategories}
          rowKey="id"
          loading={loading}
          scroll={{ x: 800 }}
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} categories${searchText ? ` (filtered from ${workCategories.length})` : ''}`,
          }}
        />

        <Modal
          title={editingCategory && workCategories.find(c => c.id === editingCategory.id) ? 'Edit Work Category' : 'Add Work Category'}
          open={editorVisible}
          onOk={handleSaveCategory}
          onCancel={() => {
            setEditorVisible(false);
            setEditingCategory(null);
            form.resetFields();
          }}
          okText="Save"
          width={600}
        >
          <Form
            form={form}
            layout="vertical"
            style={{ marginTop: '24px' }}
          >
            <Form.Item
              label="Category ID"
              name="id"
              rules={[{ required: true, message: 'ID is required' }]}
              tooltip="Unique identifier (e.g., 'footwear_manufacturing', 'jewelry_crafting')"
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

export default WorkCategoryManager;
