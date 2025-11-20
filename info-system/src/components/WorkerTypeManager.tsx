import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input, InputNumber, Select } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { WorkerType, WorkerTypesData } from '../types';
import { loadWorkerTypes, saveWorkerTypes } from '../api';

const WORKER_CATEGORIES = [
  'Agriculture',
  'Food Production',
  'Construction',
  'Production',
  'Resource Extraction',
  'Metalworking',
  'Luxury Crafts',
  'Textile',
  'Healthcare',
  'Education',
  'Commerce',
  'Finance',
  'General Labor'
];

const SKILL_LEVELS = ['Basic', 'Intermediate', 'Skilled', 'Expert'];

const WorkerTypeManager = () => {
  const [workerTypes, setWorkerTypes] = useState<WorkerType[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingWorkerType, setEditingWorkerType] = useState<WorkerType | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadWorkerTypesList();
  }, []);

  const loadWorkerTypesList = async () => {
    setLoading(true);
    try {
      const data = await loadWorkerTypes();
      setWorkerTypes(data.workerTypes);
      messageApi.success('Worker types loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load worker types: ${error}`);
      console.error('Failed to load worker types:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveWorkerTypesList = async (updatedWorkerTypes: WorkerType[]) => {
    try {
      const data: WorkerTypesData = { workerTypes: updatedWorkerTypes };
      await saveWorkerTypes(data);
      setWorkerTypes(updatedWorkerTypes);
      messageApi.success('Worker types saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save worker types: ${error}`);
      console.error('Failed to save worker types:', error);
    }
  };

  const handleAddWorkerType = () => {
    const newWorkerType: WorkerType = {
      id: 'new_worker',
      name: 'New Worker Type',
      category: 'General Labor',
      minimumWage: 10,
      skillLevel: 'Basic',
      description: ''
    };
    setEditingWorkerType(newWorkerType);
    form.setFieldsValue(newWorkerType);
    setEditorVisible(true);
  };

  const handleEditWorkerType = (workerType: WorkerType) => {
    setEditingWorkerType({ ...workerType });
    form.setFieldsValue(workerType);
    setEditorVisible(true);
  };

  const handleSaveWorkerType = () => {
    form.validateFields().then((values) => {
      const isNew = !workerTypes.find(w => w.id === editingWorkerType?.id);

      let updatedWorkerTypes: WorkerType[];
      if (isNew) {
        updatedWorkerTypes = [...workerTypes, values];
      } else {
        updatedWorkerTypes = workerTypes.map(w =>
          w.id === editingWorkerType?.id ? values : w
        );
      }

      saveWorkerTypesList(updatedWorkerTypes);
      setEditorVisible(false);
      setEditingWorkerType(null);
      form.resetFields();
    });
  };

  const handleDeleteWorkerType = async (id: string) => {
    const updatedWorkerTypes = workerTypes.filter(w => w.id !== id);
    await saveWorkerTypesList(updatedWorkerTypes);
  };

  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 120,
    },
    {
      title: 'Name',
      dataIndex: 'name',
      key: 'name',
      width: 150,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 150,
    },
    {
      title: 'Skill Level',
      dataIndex: 'skillLevel',
      key: 'skillLevel',
      width: 120,
    },
    {
      title: 'Minimum Wage ($/hr)',
      dataIndex: 'minimumWage',
      key: 'minimumWage',
      width: 150,
      align: 'center' as const,
      render: (wage: number) => `$${wage}/hr`
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
      render: (_: unknown, record: WorkerType) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditWorkerType(record)}
          />
          <Popconfirm
            title="Delete this worker type?"
            description="This action cannot be undone."
            onConfirm={() => handleDeleteWorkerType(record.id)}
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

  // Filter worker types based on search text
  const filteredWorkerTypes = workerTypes.filter(workerType => {
    const searchLower = searchText.toLowerCase();
    return (
      workerType.id.toLowerCase().includes(searchLower) ||
      workerType.name.toLowerCase().includes(searchLower) ||
      workerType.category.toLowerCase().includes(searchLower) ||
      workerType.skillLevel.toLowerCase().includes(searchLower) ||
      (workerType.description && workerType.description.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Worker Types</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddWorkerType}
          >
            Add Worker Type
          </Button>
        </div>

        <Input
          placeholder="Search worker types by ID, name, category, skill level, or description..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredWorkerTypes}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} worker types${searchText ? ` (filtered from ${workerTypes.length})` : ''}`,
          }}
        />

        <Modal
          title={editingWorkerType && workerTypes.find(w => w.id === editingWorkerType.id) ? 'Edit Worker Type' : 'Add Worker Type'}
          open={editorVisible}
          onOk={handleSaveWorkerType}
          onCancel={() => {
            setEditorVisible(false);
            setEditingWorkerType(null);
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
              label="Worker Type ID"
              name="id"
              rules={[{ required: true, message: 'ID is required' }]}
              tooltip="Unique identifier (e.g., 'carpenter', 'doctor')"
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
              <Select>
                {WORKER_CATEGORIES.map(cat => (
                  <Select.Option key={cat} value={cat}>{cat}</Select.Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              label="Skill Level"
              name="skillLevel"
              rules={[{ required: true, message: 'Skill level is required' }]}
            >
              <Select>
                {SKILL_LEVELS.map(level => (
                  <Select.Option key={level} value={level}>{level}</Select.Option>
                ))}
              </Select>
            </Form.Item>

            <Form.Item
              label="Minimum Wage ($/hour)"
              name="minimumWage"
              rules={[{ required: true, message: 'Minimum wage is required' }]}
            >
              <InputNumber
                min={1}
                step={1}
                style={{ width: '100%' }}
                prefix="$"
                suffix="/hr"
              />
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

export default WorkerTypeManager;
