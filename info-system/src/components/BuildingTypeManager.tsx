import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input, Select, InputNumber, Checkbox, Row, Col, Card } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { BuildingType, BuildingTypesData } from '../types';
import { loadBuildingTypes, saveBuildingTypes } from '../api';
import { WORK_CATEGORIES } from '../constants';
import WorkerEfficiencyEditor from './WorkerEfficiencyEditor';

const BUILDING_CATEGORIES = [
  'production',
  'agriculture',
  'residential',
  'medical',
  'education',
  'commerce',
  'resource',
  'services'
];

const BuildingTypeManager = () => {
  const [buildingTypes, setBuildingTypes] = useState<BuildingType[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingBuildingType, setEditingBuildingType] = useState<BuildingType | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');
  const [selectedWorkCategories, setSelectedWorkCategories] = useState<string[]>([]);
  const [workerEfficiencies, setWorkerEfficiencies] = useState<Record<string, number>>({});

  useEffect(() => {
    loadBuildingTypesList();
  }, []);

  const loadBuildingTypesList = async () => {
    setLoading(true);
    try {
      const data = await loadBuildingTypes();
      setBuildingTypes(data.buildingTypes);
      messageApi.success('Building types loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load building types: ${error}`);
      console.error('Failed to load building types:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveBuildingTypesList = async (updatedBuildingTypes: BuildingType[]) => {
    try {
      const data: BuildingTypesData = { buildingTypes: updatedBuildingTypes };
      await saveBuildingTypes(data);
      setBuildingTypes(updatedBuildingTypes);
      messageApi.success('Building types saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save building types: ${error}`);
      console.error('Failed to save building types:', error);
    }
  };

  const handleAddBuildingType = () => {
    const newBuildingType: BuildingType = {
      id: 'new_building',
      name: 'New Building Type',
      category: 'production',
      label: 'NB',
      color: [0.5, 0.5, 0.5],
      baseWidth: 70,
      baseHeight: 70,
      description: ''
    };
    setEditingBuildingType(newBuildingType);
    form.setFieldsValue({
      ...newBuildingType,
      colorR: 0.5,
      colorG: 0.5,
      colorB: 0.5,
    });
    setSelectedWorkCategories([]);
    setWorkerEfficiencies({});
    setEditorVisible(true);
  };

  const handleEditBuildingType = (buildingType: BuildingType) => {
    setEditingBuildingType({ ...buildingType });
    form.setFieldsValue({
      ...buildingType,
      colorR: buildingType.color[0],
      colorG: buildingType.color[1],
      colorB: buildingType.color[2],
    });
    setSelectedWorkCategories(buildingType.workCategories || []);
    setWorkerEfficiencies(buildingType.workerEfficiency || {});
    setEditorVisible(true);
  };

  const handleSaveBuildingType = () => {
    form.validateFields().then((values) => {
      const isNew = !buildingTypes.find(b => b.id === editingBuildingType?.id);

      // Construct color array from individual RGB values
      const color: [number, number, number] = [
        values.colorR ?? 0.5,
        values.colorG ?? 0.5,
        values.colorB ?? 0.5,
      ];

      // Remove individual color fields and add color array
      const { colorR, colorG, colorB, ...restValues } = values;

      const buildingTypeData: BuildingType = {
        ...restValues,
        color,
        workerEfficiency: workerEfficiencies
      };

      let updatedBuildingTypes: BuildingType[];
      if (isNew) {
        updatedBuildingTypes = [...buildingTypes, buildingTypeData];
      } else {
        updatedBuildingTypes = buildingTypes.map(b =>
          b.id === editingBuildingType?.id ? buildingTypeData : b
        );
      }

      saveBuildingTypesList(updatedBuildingTypes);
      setEditorVisible(false);
      setEditingBuildingType(null);
      form.resetFields();
      setSelectedWorkCategories([]);
      setWorkerEfficiencies({});
    });
  };

  const handleDeleteBuildingType = async (id: string) => {
    const updatedBuildingTypes = buildingTypes.filter(b => b.id !== id);
    await saveBuildingTypesList(updatedBuildingTypes);
  };

  const columns = [
    {
      title: 'Label',
      dataIndex: 'label',
      key: 'label',
      width: 70,
      render: (label: string, record: BuildingType) => (
        <div style={{
          display: 'inline-block',
          padding: '2px 8px',
          backgroundColor: `rgb(${record.color[0] * 255}, ${record.color[1] * 255}, ${record.color[2] * 255})`,
          color: 'white',
          borderRadius: '4px',
          fontWeight: 'bold'
        }}>
          {label}
        </div>
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
      width: 150,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 120,
    },
    {
      title: 'Size',
      key: 'size',
      width: 100,
      render: (_: unknown, record: BuildingType) => (
        <span>{record.baseWidth}×{record.baseHeight}</span>
      ),
    },
    {
      title: 'Work Categories',
      dataIndex: 'workCategories',
      key: 'workCategories',
      width: 200,
      render: (categories: string[] | undefined) => {
        if (!categories || categories.length === 0) {
          return <span style={{ color: '#999' }}>None</span>;
        }
        return categories.slice(0, 2).join(', ') + (categories.length > 2 ? '...' : '');
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: unknown, record: BuildingType) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditBuildingType(record)}
          />
          <Popconfirm
            title="Delete this building type?"
            description="This action cannot be undone."
            onConfirm={() => handleDeleteBuildingType(record.id)}
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

  // Filter building types based on search text
  const filteredBuildingTypes = buildingTypes.filter(buildingType => {
    const searchLower = searchText.toLowerCase();
    return (
      buildingType.id.toLowerCase().includes(searchLower) ||
      buildingType.name.toLowerCase().includes(searchLower) ||
      buildingType.category.toLowerCase().includes(searchLower) ||
      (buildingType.description && buildingType.description.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Building Types</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddBuildingType}
          >
            Add Building Type
          </Button>
        </div>

        <Input
          placeholder="Search building types..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredBuildingTypes}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} building types${searchText ? ` (filtered from ${buildingTypes.length})` : ''}`,
          }}
        />

        <Modal
          title={editingBuildingType && buildingTypes.find(b => b.id === editingBuildingType.id) ? 'Edit Building Type' : 'Add Building Type'}
          open={editorVisible}
          onOk={handleSaveBuildingType}
          onCancel={() => {
            setEditorVisible(false);
            setEditingBuildingType(null);
            form.resetFields();
            setSelectedWorkCategories([]);
            setWorkerEfficiencies({});
          }}
          okText="Save"
          width={800}
        >
          <Form
            form={form}
            layout="vertical"
            style={{ marginTop: '24px' }}
          >
            <Card title="Basic Information" style={{ marginBottom: 16 }}>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Building Type ID"
                    name="id"
                    rules={[{ required: true, message: 'ID is required' }]}
                    tooltip="Unique identifier (e.g., 'sawmill', 'bakery')"
                  >
                    <Input />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Name"
                    name="name"
                    rules={[{ required: true, message: 'Name is required' }]}
                  >
                    <Input />
                  </Form.Item>
                </Col>
              </Row>

              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item
                    label="Category"
                    name="category"
                    rules={[{ required: true, message: 'Category is required' }]}
                  >
                    <Select>
                      {BUILDING_CATEGORIES.map(cat => (
                        <Select.Option key={cat} value={cat}>{cat}</Select.Option>
                      ))}
                    </Select>
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    label="Label (2 chars)"
                    name="label"
                    rules={[
                      { required: true, message: 'Label is required' },
                      { max: 3, message: 'Max 3 characters' }
                    ]}
                    tooltip="2-3 letter abbreviation shown in UI"
                  >
                    <Input maxLength={3} />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                label="Description"
                name="description"
              >
                <Input.TextArea rows={2} />
              </Form.Item>
            </Card>

            <Card title="Visual Properties" style={{ marginBottom: 16 }}>
              <Row gutter={16}>
                <Col span={8}>
                  <Form.Item
                    label="Color Red"
                    name="colorR"
                    rules={[{ required: true, message: 'Required' }]}
                  >
                    <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    label="Color Green"
                    name="colorG"
                    rules={[{ required: true, message: 'Required' }]}
                  >
                    <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={8}>
                  <Form.Item
                    label="Color Blue"
                    name="colorB"
                    rules={[{ required: true, message: 'Required' }]}
                  >
                    <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>
              <div style={{
                marginTop: 8,
                marginBottom: 16,
                padding: '20px',
                backgroundColor: `rgb(${(form.getFieldValue('colorR') ?? 0.5) * 255}, ${(form.getFieldValue('colorG') ?? 0.5) * 255}, ${(form.getFieldValue('colorB') ?? 0.5) * 255})`,
                borderRadius: '4px',
                textAlign: 'center',
                color: 'white',
                fontWeight: 'bold'
              }}>
                Color Preview
              </div>
            </Card>

            <Card title="Size Properties" style={{ marginBottom: 16 }}>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Base Width"
                    name="baseWidth"
                    rules={[{ required: true, message: 'Required' }]}
                  >
                    <InputNumber min={10} max={500} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Base Height"
                    name="baseHeight"
                    rules={[{ required: true, message: 'Required' }]}
                  >
                    <InputNumber min={10} max={500} style={{ width: '100%' }} />
                  </Form.Item>
                </Col>
              </Row>

              <Form.Item
                name="variableSize"
                valuePropName="checked"
              >
                <Checkbox>Variable Size</Checkbox>
              </Form.Item>

              <Form.Item noStyle shouldUpdate={(prev, curr) => prev.variableSize !== curr.variableSize}>
                {({ getFieldValue }) =>
                  getFieldValue('variableSize') ? (
                    <Row gutter={16}>
                      <Col span={6}>
                        <Form.Item
                          label="Min Width"
                          name="minWidth"
                        >
                          <InputNumber min={10} max={500} style={{ width: '100%' }} />
                        </Form.Item>
                      </Col>
                      <Col span={6}>
                        <Form.Item
                          label="Min Height"
                          name="minHeight"
                        >
                          <InputNumber min={10} max={500} style={{ width: '100%' }} />
                        </Form.Item>
                      </Col>
                      <Col span={6}>
                        <Form.Item
                          label="Max Width"
                          name="maxWidth"
                        >
                          <InputNumber min={10} max={1000} style={{ width: '100%' }} />
                        </Form.Item>
                      </Col>
                      <Col span={6}>
                        <Form.Item
                          label="Max Height"
                          name="maxHeight"
                        >
                          <InputNumber min={10} max={1000} style={{ width: '100%' }} />
                        </Form.Item>
                      </Col>
                    </Row>
                  ) : null
                }
              </Form.Item>
            </Card>

            <Card title="Worker Configuration" style={{ marginBottom: 16 }}>
              <Form.Item
                label="Work Categories"
                name="workCategories"
                tooltip="Select which types of workers can work at this building"
              >
                <Select
                  mode="multiple"
                  placeholder="Select work categories"
                  style={{ width: '100%' }}
                  onChange={(value) => setSelectedWorkCategories(value as string[])}
                >
                  {WORK_CATEGORIES.map(category => (
                    <Select.Option key={category} value={category}>{category}</Select.Option>
                  ))}
                </Select>
              </Form.Item>

              <Form.Item
                label="Worker Efficiency"
                tooltip="Set efficiency multiplier for each work category"
              >
                <WorkerEfficiencyEditor
                  workCategories={selectedWorkCategories}
                  efficiencies={workerEfficiencies}
                  onChange={setWorkerEfficiencies}
                />
              </Form.Item>
            </Card>
          </Form>
        </Modal>
      </div>
    </>
  );
};

export default BuildingTypeManager;
