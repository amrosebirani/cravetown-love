import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Input, Form, Tag, Card, Typography } from 'antd';
import { PlusOutlined, CopyOutlined, DeleteOutlined, EditOutlined, CheckCircleOutlined } from '@ant-design/icons';
import type { GameVersion, VersionsManifest } from '../types';
import {
  loadVersionsManifest,
  createNewVersion,
  cloneVersion,
  deleteVersion,
  switchActiveVersion,
  updateVersionMetadata
} from '../api';

const { TextArea } = Input;
const { Title, Text } = Typography;

const VersionManager = () => {
  const [versions, setVersions] = useState<GameVersion[]>([]);
  const [activeVersionId, setActiveVersionId] = useState<string>('base');
  const [loading, setLoading] = useState(false);
  const [createModalVisible, setCreateModalVisible] = useState(false);
  const [cloneModalVisible, setCloneModalVisible] = useState(false);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [selectedVersion, setSelectedVersion] = useState<GameVersion | null>(null);
  const [messageApi, contextHolder] = message.useMessage();
  const [createForm] = Form.useForm();
  const [cloneForm] = Form.useForm();
  const [editForm] = Form.useForm();

  useEffect(() => {
    loadVersions();
  }, []);

  const loadVersions = async () => {
    setLoading(true);
    try {
      const manifest = await loadVersionsManifest();
      setVersions(manifest.versions);
      setActiveVersionId(manifest.activeVersion);
      messageApi.success('Versions loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load versions: ${error}`);
      console.error('Failed to load versions:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateVersion = async (values: any) => {
    try {
      await createNewVersion(
        values.id,
        values.name,
        values.description,
        values.author
      );
      messageApi.success('Version created successfully');
      setCreateModalVisible(false);
      createForm.resetFields();
      await loadVersions();
    } catch (error) {
      messageApi.error(`Failed to create version: ${error}`);
      console.error('Failed to create version:', error);
    }
  };

  const handleCloneVersion = async (values: any) => {
    if (!selectedVersion) return;

    try {
      await cloneVersion(
        selectedVersion.id,
        values.id,
        values.name,
        values.author
      );
      messageApi.success(`Version cloned from ${selectedVersion.name}`);
      setCloneModalVisible(false);
      cloneForm.resetFields();
      setSelectedVersion(null);
      await loadVersions();
    } catch (error) {
      messageApi.error(`Failed to clone version: ${error}`);
      console.error('Failed to clone version:', error);
    }
  };

  const handleDeleteVersion = async (versionId: string) => {
    try {
      await deleteVersion(versionId);
      messageApi.success('Version deleted successfully');
      await loadVersions();
    } catch (error) {
      messageApi.error(`Failed to delete version: ${error}`);
      console.error('Failed to delete version:', error);
    }
  };

  const handleSwitchActiveVersion = async (versionId: string) => {
    try {
      await switchActiveVersion(versionId);
      setActiveVersionId(versionId);
      messageApi.success(`Switched to version: ${versions.find(v => v.id === versionId)?.name}`);
      await loadVersions();

      // Reload the page to ensure all components use the new version
      setTimeout(() => {
        window.location.reload();
      }, 1000);
    } catch (error) {
      messageApi.error(`Failed to switch version: ${error}`);
      console.error('Failed to switch version:', error);
    }
  };

  const handleUpdateMetadata = async (values: any) => {
    if (!selectedVersion) return;

    try {
      await updateVersionMetadata(selectedVersion.id, {
        name: values.name,
        description: values.description,
        author: values.author,
        tags: values.tags?.split(',').map((t: string) => t.trim()).filter(Boolean) || []
      });
      messageApi.success('Version metadata updated successfully');
      setEditModalVisible(false);
      editForm.resetFields();
      setSelectedVersion(null);
      await loadVersions();
    } catch (error) {
      messageApi.error(`Failed to update version metadata: ${error}`);
      console.error('Failed to update version metadata:', error);
    }
  };

  const openCloneModal = (version: GameVersion) => {
    setSelectedVersion(version);
    cloneForm.setFieldsValue({
      id: `${version.id}_copy`,
      name: `${version.name} (Copy)`,
      author: version.author
    });
    setCloneModalVisible(true);
  };

  const openEditModal = (version: GameVersion) => {
    setSelectedVersion(version);
    editForm.setFieldsValue({
      name: version.name,
      description: version.description,
      author: version.author,
      tags: version.tags?.join(', ') || ''
    });
    setEditModalVisible(true);
  };

  const columns = [
    {
      title: 'Status',
      key: 'active',
      width: 80,
      render: (_: unknown, record: GameVersion) => (
        record.active ? (
          <Tag icon={<CheckCircleOutlined />} color="success">Active</Tag>
        ) : null
      ),
    },
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
      width: 180,
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      width: 250,
    },
    {
      title: 'Author',
      dataIndex: 'author',
      key: 'author',
      width: 120,
    },
    {
      title: 'Version',
      dataIndex: 'version',
      key: 'version',
      width: 80,
    },
    {
      title: 'Tags',
      key: 'tags',
      width: 150,
      render: (_: unknown, record: GameVersion) => (
        <>
          {record.tags?.map(tag => (
            <Tag key={tag} color="blue">{tag}</Tag>
          ))}
        </>
      ),
    },
    {
      title: 'Created',
      dataIndex: 'createdDate',
      key: 'createdDate',
      width: 100,
    },
    {
      title: 'Modified',
      dataIndex: 'lastModified',
      key: 'lastModified',
      width: 100,
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 240,
      fixed: 'right' as const,
      render: (_: unknown, record: GameVersion) => (
        <Space>
          {!record.active && (
            <Button
              type="primary"
              size="small"
              onClick={() => handleSwitchActiveVersion(record.id)}
            >
              Activate
            </Button>
          )}
          <Button
            type="default"
            size="small"
            icon={<EditOutlined />}
            onClick={() => openEditModal(record)}
          />
          <Button
            type="default"
            size="small"
            icon={<CopyOutlined />}
            onClick={() => openCloneModal(record)}
          />
          {record.id !== 'base' && !record.active && (
            <Popconfirm
              title="Delete this version?"
              description="This action cannot be undone. All data will be permanently deleted."
              onConfirm={() => handleDeleteVersion(record.id)}
              okText="Yes"
              cancelText="No"
            >
              <Button
                type="link"
                danger
                size="small"
                icon={<DeleteOutlined />}
              />
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  return (
    <>
      {contextHolder}
      <div>
        <Card style={{ marginBottom: 16 }}>
          <Space direction="vertical" style={{ width: '100%' }}>
            <Title level={4} style={{ margin: 0 }}>Active Version</Title>
            <Text>
              Currently working on: <Tag color="green">{versions.find(v => v.id === activeVersionId)?.name || activeVersionId}</Tag>
            </Text>
            <Text type="secondary">
              All changes you make will be saved to this version. Switch versions to work on different game data configurations.
            </Text>
          </Space>
        </Card>

        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Game Versions</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setCreateModalVisible(true)}
          >
            Create New Version
          </Button>
        </div>

        <Table
          columns={columns}
          dataSource={versions}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1400 }}
          pagination={{
            pageSize: 10,
            showTotal: (total) => `Total ${total} versions`,
          }}
        />

        {/* Create New Version Modal */}
        <Modal
          title="Create New Version"
          open={createModalVisible}
          onCancel={() => {
            setCreateModalVisible(false);
            createForm.resetFields();
          }}
          footer={null}
          width={600}
        >
          <Form
            form={createForm}
            layout="vertical"
            onFinish={handleCreateVersion}
          >
            <Form.Item
              name="id"
              label="Version ID"
              rules={[
                { required: true, message: 'Please enter a version ID' },
                { pattern: /^[a-z0-9_-]+$/, message: 'Only lowercase letters, numbers, hyphens, and underscores allowed' }
              ]}
            >
              <Input placeholder="e.g., medieval, apocalyptic" />
            </Form.Item>

            <Form.Item
              name="name"
              label="Version Name"
              rules={[{ required: true, message: 'Please enter a version name' }]}
            >
              <Input placeholder="e.g., Medieval Era, Post-Apocalyptic" />
            </Form.Item>

            <Form.Item
              name="description"
              label="Description"
              rules={[{ required: true, message: 'Please enter a description' }]}
            >
              <TextArea rows={3} placeholder="Describe this version..." />
            </Form.Item>

            <Form.Item
              name="author"
              label="Author"
              rules={[{ required: true, message: 'Please enter your name' }]}
            >
              <Input placeholder="Your name" />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit">
                  Create Version
                </Button>
                <Button onClick={() => {
                  setCreateModalVisible(false);
                  createForm.resetFields();
                }}>
                  Cancel
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Modal>

        {/* Clone Version Modal */}
        <Modal
          title={`Clone Version: ${selectedVersion?.name}`}
          open={cloneModalVisible}
          onCancel={() => {
            setCloneModalVisible(false);
            cloneForm.resetFields();
            setSelectedVersion(null);
          }}
          footer={null}
          width={600}
        >
          <Form
            form={cloneForm}
            layout="vertical"
            onFinish={handleCloneVersion}
          >
            <Form.Item
              name="id"
              label="New Version ID"
              rules={[
                { required: true, message: 'Please enter a version ID' },
                { pattern: /^[a-z0-9_-]+$/, message: 'Only lowercase letters, numbers, hyphens, and underscores allowed' }
              ]}
            >
              <Input placeholder="e.g., medieval_v2" />
            </Form.Item>

            <Form.Item
              name="name"
              label="New Version Name"
              rules={[{ required: true, message: 'Please enter a version name' }]}
            >
              <Input placeholder="e.g., Medieval Era v2" />
            </Form.Item>

            <Form.Item
              name="author"
              label="Author"
              rules={[{ required: true, message: 'Please enter your name' }]}
            >
              <Input placeholder="Your name" />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit">
                  Clone Version
                </Button>
                <Button onClick={() => {
                  setCloneModalVisible(false);
                  cloneForm.resetFields();
                  setSelectedVersion(null);
                }}>
                  Cancel
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Modal>

        {/* Edit Version Metadata Modal */}
        <Modal
          title={`Edit Version: ${selectedVersion?.name}`}
          open={editModalVisible}
          onCancel={() => {
            setEditModalVisible(false);
            editForm.resetFields();
            setSelectedVersion(null);
          }}
          footer={null}
          width={600}
        >
          <Form
            form={editForm}
            layout="vertical"
            onFinish={handleUpdateMetadata}
          >
            <Form.Item
              name="name"
              label="Version Name"
              rules={[{ required: true, message: 'Please enter a version name' }]}
            >
              <Input placeholder="e.g., Medieval Era" />
            </Form.Item>

            <Form.Item
              name="description"
              label="Description"
              rules={[{ required: true, message: 'Please enter a description' }]}
            >
              <TextArea rows={3} placeholder="Describe this version..." />
            </Form.Item>

            <Form.Item
              name="author"
              label="Author"
              rules={[{ required: true, message: 'Please enter author name' }]}
            >
              <Input placeholder="Author name" />
            </Form.Item>

            <Form.Item
              name="tags"
              label="Tags (comma-separated)"
            >
              <Input placeholder="e.g., medieval, historical, fantasy" />
            </Form.Item>

            <Form.Item>
              <Space>
                <Button type="primary" htmlType="submit">
                  Save Changes
                </Button>
                <Button onClick={() => {
                  setEditModalVisible(false);
                  editForm.resetFields();
                  setSelectedVersion(null);
                }}>
                  Cancel
                </Button>
              </Space>
            </Form.Item>
          </Form>
        </Modal>
      </div>
    </>
  );
};

export default VersionManager;
