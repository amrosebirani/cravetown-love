import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Form, Input, Select, InputNumber, Row, Col, Card, Tabs, Divider, Tag, Switch } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined, UpOutlined, DownOutlined, MinusCircleOutlined } from '@ant-design/icons';
import type { BuildingType, BuildingTypesData, BuildingUpgradeLevel, PlacementConstraints, ResourceRequirement } from '../types';
import { loadBuildingTypes, saveBuildingTypes } from '../api';
import { WORK_CATEGORIES, NATURAL_RESOURCE_IDS, EFFICIENCY_FORMULAS } from '../constants';
import WorkerEfficiencyEditor from './WorkerEfficiencyEditor';

const { TabPane } = Tabs;

const BUILDING_CATEGORIES = [
  'production',
  'agriculture',
  'extraction',
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
  const [upgradeLevels, setUpgradeLevels] = useState<BuildingUpgradeLevel[]>([]);
  const [placementConstraints, setPlacementConstraints] = useState<PlacementConstraints>({
    enabled: false,
    requiredResources: [],
    efficiencyFormula: 'weighted_average',
    warningThreshold: 0.4,
    blockingThreshold: 0.2
  });

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
    const defaultLevel0: BuildingUpgradeLevel = {
      level: 0,
      name: 'Basic',
      description: 'Basic building level',
      stations: 2,
      width: 80,
      height: 80,
      constructionMaterials: { wood: 20, stone: 10 },
      storage: {
        inputCapacity: 200,
        outputCapacity: 200
      }
    };

    const newBuildingType: BuildingType = {
      id: 'new_building',
      name: 'New Building Type',
      category: 'production',
      label: 'NB',
      color: [0.5, 0.5, 0.5],
      description: '',
      upgradeLevels: [defaultLevel0]
    };

    setEditingBuildingType(newBuildingType);
    form.setFieldsValue({
      id: newBuildingType.id,
      name: newBuildingType.name,
      category: newBuildingType.category,
      label: newBuildingType.label,
      description: newBuildingType.description,
      colorR: 0.5,
      colorG: 0.5,
      colorB: 0.5,
    });
    setSelectedWorkCategories([]);
    setWorkerEfficiencies({});
    setUpgradeLevels([defaultLevel0]);
    setPlacementConstraints({
      enabled: false,
      requiredResources: [],
      efficiencyFormula: 'weighted_average',
      warningThreshold: 0.4,
      blockingThreshold: 0.2
    });
    setEditorVisible(true);
  };

  const handleEditBuildingType = (buildingType: BuildingType) => {
    setEditingBuildingType({ ...buildingType });
    form.setFieldsValue({
      id: buildingType.id,
      name: buildingType.name,
      category: buildingType.category,
      label: buildingType.label,
      description: buildingType.description,
      colorR: buildingType.color[0],
      colorG: buildingType.color[1],
      colorB: buildingType.color[2],
    });
    setSelectedWorkCategories(buildingType.workCategories || []);
    setWorkerEfficiencies(buildingType.workerEfficiency || {});
    setUpgradeLevels(buildingType.upgradeLevels || []);
    setPlacementConstraints(buildingType.placementConstraints || {
      enabled: false,
      requiredResources: [],
      efficiencyFormula: 'weighted_average',
      warningThreshold: 0.4,
      blockingThreshold: 0.2
    });
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

      // Remove individual color fields
      const { colorR, colorG, colorB, ...restValues } = values;

      const buildingTypeData: BuildingType = {
        ...restValues,
        color,
        workCategories: selectedWorkCategories,
        workerEfficiency: workerEfficiencies,
        upgradeLevels: upgradeLevels,
        placementConstraints: placementConstraints.enabled ? placementConstraints : { enabled: false }
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
      setUpgradeLevels([]);
      setPlacementConstraints({
        enabled: false,
        requiredResources: [],
        efficiencyFormula: 'weighted_average',
        warningThreshold: 0.4,
        blockingThreshold: 0.2
      });
    });
  };

  // Placement constraint helpers
  const handleAddResourceRequirement = () => {
    const newRequirement: ResourceRequirement = {
      resourceId: NATURAL_RESOURCE_IDS[0],
      weight: 1.0,
      minValue: 0.2,
      displayName: 'New Resource'
    };
    setPlacementConstraints({
      ...placementConstraints,
      requiredResources: [...(placementConstraints.requiredResources || []), newRequirement]
    });
  };

  const handleUpdateResourceRequirement = (index: number, updates: Partial<ResourceRequirement>) => {
    const newRequirements = [...(placementConstraints.requiredResources || [])];
    newRequirements[index] = { ...newRequirements[index], ...updates };
    setPlacementConstraints({
      ...placementConstraints,
      requiredResources: newRequirements
    });
  };

  const handleRemoveResourceRequirement = (index: number) => {
    const newRequirements = (placementConstraints.requiredResources || []).filter((_, i) => i !== index);
    setPlacementConstraints({
      ...placementConstraints,
      requiredResources: newRequirements
    });
  };

  const handleDeleteBuildingType = async (id: string) => {
    const updatedBuildingTypes = buildingTypes.filter(b => b.id !== id);
    await saveBuildingTypesList(updatedBuildingTypes);
  };

  const handleAddUpgradeLevel = () => {
    const newLevel = upgradeLevels.length;
    const prevLevel = upgradeLevels[upgradeLevels.length - 1];

    const newUpgradeLevel: BuildingUpgradeLevel = {
      level: newLevel,
      name: `Level ${newLevel}`,
      description: `Upgrade level ${newLevel}`,
      stations: prevLevel ? prevLevel.stations + 2 : 2,
      width: prevLevel ? prevLevel.width + 20 : 100,
      height: prevLevel ? prevLevel.height + 20 : 100,
      upgradeMaterials: { wood: 30, stone: 20 },
      storage: {
        inputCapacity: prevLevel ? prevLevel.storage.inputCapacity + 100 : 300,
        outputCapacity: prevLevel ? prevLevel.storage.outputCapacity + 100 : 300
      }
    };

    setUpgradeLevels([...upgradeLevels, newUpgradeLevel]);
  };

  const handleUpdateUpgradeLevel = (index: number, updatedLevel: Partial<BuildingUpgradeLevel>) => {
    const newLevels = [...upgradeLevels];
    newLevels[index] = { ...newLevels[index], ...updatedLevel };
    setUpgradeLevels(newLevels);
  };

  const handleDeleteUpgradeLevel = (index: number) => {
    if (index === 0) {
      message.error('Cannot delete level 0 (base level)');
      return;
    }
    const newLevels = upgradeLevels.filter((_, i) => i !== index);
    // Re-index levels
    const reindexed = newLevels.map((level, i) => ({ ...level, level: i }));
    setUpgradeLevels(reindexed);
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
      title: 'Upgrade Levels',
      key: 'levels',
      width: 120,
      render: (_: unknown, record: BuildingType) => (
        <span>{record.upgradeLevels?.length || 0} levels</span>
      ),
    },
    {
      title: 'Max Stations',
      key: 'maxStations',
      width: 100,
      render: (_: unknown, record: BuildingType) => {
        const maxLevel = record.upgradeLevels?.[record.upgradeLevels.length - 1];
        return <span>{maxLevel?.stations || '-'}</span>;
      },
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
          scroll={{ x: 1200 }}
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
            setUpgradeLevels([]);
          }}
          okText="Save"
          width={900}
          style={{ top: 20 }}
          bodyStyle={{ maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' }}
        >
          <Tabs defaultActiveKey="basic">
            <TabPane tab="Basic Info" key="basic">
              <Form
                form={form}
                layout="vertical"
                style={{ marginTop: '16px' }}
              >
                <Card title="Basic Information" size="small" style={{ marginBottom: 16 }}>
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
                    <Col span={12}>
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
                    <Col span={12}>
                      <Form.Item
                        label="Label (2-3 chars)"
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

                <Card title="Visual Properties" size="small" style={{ marginBottom: 16 }}>
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
                    padding: '20px',
                    backgroundColor: `rgb(${(form.getFieldValue('colorR') ?? 0.5) * 255}, ${(form.getFieldValue('colorG') ?? 0.5) * 255}, ${(form.getFieldValue('colorB') ?? 0.5) * 255})`,
                    borderRadius: '4px',
                    textAlign: 'center',
                    color: 'white',
                    fontWeight: 'bold'
                  }}>
                    Color Preview: {form.getFieldValue('label') || 'NB'}
                  </div>
                </Card>

                <Card title="Worker Configuration" size="small" style={{ marginBottom: 16 }}>
                  <Form.Item
                    label="Work Categories"
                    tooltip="Select which types of workers can work at this building"
                  >
                    <Select
                      mode="multiple"
                      placeholder="Select work categories"
                      value={selectedWorkCategories}
                      onChange={(value) => setSelectedWorkCategories(value as string[])}
                      style={{ width: '100%' }}
                    >
                      {WORK_CATEGORIES.map(category => (
                        <Select.Option key={category} value={category}>{category}</Select.Option>
                      ))}
                    </Select>
                  </Form.Item>

                  <Form.Item
                    label="Worker Efficiency"
                    tooltip="Set efficiency multiplier for each work category (0.0 to 1.0)"
                  >
                    <WorkerEfficiencyEditor
                      workCategories={selectedWorkCategories}
                      efficiencies={workerEfficiencies}
                      onChange={setWorkerEfficiencies}
                    />
                  </Form.Item>
                </Card>
              </Form>
            </TabPane>

            <TabPane tab={`Upgrade Levels (${upgradeLevels.length})`} key="levels">
              <div style={{ marginTop: 16, marginBottom: 16 }}>
                <Button
                  type="dashed"
                  icon={<PlusOutlined />}
                  onClick={handleAddUpgradeLevel}
                  style={{ width: '100%' }}
                >
                  Add Upgrade Level
                </Button>
              </div>

              {upgradeLevels.map((level, index) => (
                <Card
                  key={index}
                  title={
                    <Space>
                      <Tag color="blue">Level {level.level}</Tag>
                      <Input
                        value={level.name}
                        onChange={(e) => handleUpdateUpgradeLevel(index, { name: e.target.value })}
                        style={{ width: 200 }}
                        placeholder="Level name"
                      />
                    </Space>
                  }
                  size="small"
                  style={{ marginBottom: 16 }}
                  extra={
                    index > 0 && (
                      <Popconfirm
                        title="Delete this upgrade level?"
                        onConfirm={() => handleDeleteUpgradeLevel(index)}
                        okText="Yes"
                        cancelText="No"
                      >
                        <Button type="link" danger icon={<DeleteOutlined />} />
                      </Popconfirm>
                    )
                  }
                >
                  <Row gutter={16}>
                    <Col span={24}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Description:</strong>
                        <Input.TextArea
                          value={level.description}
                          onChange={(e) => handleUpdateUpgradeLevel(index, { description: e.target.value })}
                          rows={2}
                          placeholder="Level description"
                        />
                      </div>
                    </Col>
                  </Row>

                  <Divider style={{ margin: '12px 0' }} />

                  <Row gutter={16}>
                    <Col span={8}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Stations:</strong>
                        <InputNumber
                          value={level.stations}
                          onChange={(value) => handleUpdateUpgradeLevel(index, { stations: value || 1 })}
                          min={1}
                          max={20}
                          style={{ width: '100%' }}
                        />
                      </div>
                    </Col>
                    <Col span={8}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Width:</strong>
                        <InputNumber
                          value={level.width}
                          onChange={(value) => handleUpdateUpgradeLevel(index, { width: value || 80 })}
                          min={40}
                          max={500}
                          style={{ width: '100%' }}
                        />
                      </div>
                    </Col>
                    <Col span={8}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Height:</strong>
                        <InputNumber
                          value={level.height}
                          onChange={(value) => handleUpdateUpgradeLevel(index, { height: value || 80 })}
                          min={40}
                          max={500}
                          style={{ width: '100%' }}
                        />
                      </div>
                    </Col>
                  </Row>

                  <Divider style={{ margin: '12px 0' }}>Storage</Divider>

                  <Row gutter={16}>
                    <Col span={12}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Input Capacity:</strong>
                        <InputNumber
                          value={level.storage.inputCapacity}
                          onChange={(value) => handleUpdateUpgradeLevel(index, {
                            storage: { ...level.storage, inputCapacity: value || 100 }
                          })}
                          min={0}
                          max={10000}
                          style={{ width: '100%' }}
                        />
                      </div>
                    </Col>
                    <Col span={12}>
                      <div style={{ marginBottom: 8 }}>
                        <strong>Output Capacity:</strong>
                        <InputNumber
                          value={level.storage.outputCapacity}
                          onChange={(value) => handleUpdateUpgradeLevel(index, {
                            storage: { ...level.storage, outputCapacity: value || 100 }
                          })}
                          min={0}
                          max={10000}
                          style={{ width: '100%' }}
                        />
                      </div>
                    </Col>
                  </Row>

                  <Divider style={{ margin: '12px 0' }}>
                    {level.level === 0 ? 'Construction Materials' : 'Upgrade Materials'}
                  </Divider>

                  <div style={{ marginBottom: 8 }}>
                    <Input.TextArea
                      value={JSON.stringify(level.level === 0 ? level.constructionMaterials : level.upgradeMaterials, null, 2)}
                      onChange={(e) => {
                        try {
                          const materials = JSON.parse(e.target.value);
                          if (level.level === 0) {
                            handleUpdateUpgradeLevel(index, { constructionMaterials: materials });
                          } else {
                            handleUpdateUpgradeLevel(index, { upgradeMaterials: materials });
                          }
                        } catch (err) {
                          // Invalid JSON, ignore
                        }
                      }}
                      rows={3}
                      placeholder='{"wood": 20, "stone": 10}'
                      style={{ fontFamily: 'monospace', fontSize: '12px' }}
                    />
                    <div style={{ fontSize: '11px', color: '#666', marginTop: 4 }}>
                      JSON format: {`{"commodity": amount, ...}`}
                    </div>
                  </div>
                </Card>
              ))}

              {upgradeLevels.length === 0 && (
                <div style={{ textAlign: 'center', padding: '40px', color: '#999' }}>
                  No upgrade levels defined. Click "Add Upgrade Level" to start.
                </div>
              )}
            </TabPane>

            <TabPane tab="Placement Constraints" key="constraints">
              <div style={{ marginTop: 16 }}>
                <Card title="Resource Constraints" size="small" style={{ marginBottom: 16 }}>
                  <Row gutter={16} style={{ marginBottom: 16 }}>
                    <Col span={12}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span>Enable Constraints:</span>
                        <Switch
                          checked={placementConstraints.enabled}
                          onChange={(checked) => setPlacementConstraints({
                            ...placementConstraints,
                            enabled: checked
                          })}
                        />
                      </div>
                    </Col>
                    <Col span={12}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span>Efficiency Formula:</span>
                        <Select
                          value={placementConstraints.efficiencyFormula}
                          onChange={(value) => setPlacementConstraints({
                            ...placementConstraints,
                            efficiencyFormula: value
                          })}
                          style={{ width: 150 }}
                          disabled={!placementConstraints.enabled}
                        >
                          {EFFICIENCY_FORMULAS.map(f => (
                            <Select.Option key={f} value={f}>{f.replace('_', ' ')}</Select.Option>
                          ))}
                        </Select>
                      </div>
                    </Col>
                  </Row>

                  {placementConstraints.enabled && (
                    <>
                      <Row gutter={16} style={{ marginBottom: 16 }}>
                        <Col span={12}>
                          <div>
                            <strong>Warning Threshold:</strong>
                            <InputNumber
                              value={placementConstraints.warningThreshold}
                              onChange={(value) => setPlacementConstraints({
                                ...placementConstraints,
                                warningThreshold: value || 0.4
                              })}
                              min={0}
                              max={1}
                              step={0.1}
                              style={{ width: '100%' }}
                            />
                            <div style={{ fontSize: '11px', color: '#666' }}>
                              Below this: show warning (yellow)
                            </div>
                          </div>
                        </Col>
                        <Col span={12}>
                          <div>
                            <strong>Blocking Threshold:</strong>
                            <InputNumber
                              value={placementConstraints.blockingThreshold}
                              onChange={(value) => setPlacementConstraints({
                                ...placementConstraints,
                                blockingThreshold: value || 0.2
                              })}
                              min={0}
                              max={1}
                              step={0.1}
                              style={{ width: '100%' }}
                            />
                            <div style={{ fontSize: '11px', color: '#666' }}>
                              Below this: cannot place (red)
                            </div>
                          </div>
                        </Col>
                      </Row>

                      <Divider style={{ margin: '12px 0' }}>Required Resources</Divider>

                      <Button
                        type="dashed"
                        icon={<PlusOutlined />}
                        onClick={handleAddResourceRequirement}
                        style={{ width: '100%', marginBottom: 16 }}
                      >
                        Add Resource Requirement
                      </Button>

                      {(placementConstraints.requiredResources || []).map((req, index) => (
                        <Card
                          key={index}
                          size="small"
                          style={{ marginBottom: 8 }}
                          extra={
                            <Button
                              type="link"
                              danger
                              icon={<MinusCircleOutlined />}
                              onClick={() => handleRemoveResourceRequirement(index)}
                            />
                          }
                        >
                          <Row gutter={16}>
                            <Col span={8}>
                              <div>
                                <strong>Resource:</strong>
                                <Select
                                  value={req.resourceId}
                                  onChange={(value) => handleUpdateResourceRequirement(index, { resourceId: value })}
                                  style={{ width: '100%' }}
                                >
                                  {NATURAL_RESOURCE_IDS.map(id => (
                                    <Select.Option key={id} value={id}>{id.replace('_', ' ')}</Select.Option>
                                  ))}
                                  <Select.Option value="ore_any">Any Ore (special)</Select.Option>
                                </Select>
                              </div>
                            </Col>
                            <Col span={8}>
                              <div>
                                <strong>Display Name:</strong>
                                <Input
                                  value={req.displayName}
                                  onChange={(e) => handleUpdateResourceRequirement(index, { displayName: e.target.value })}
                                />
                              </div>
                            </Col>
                            <Col span={4}>
                              <div>
                                <strong>Weight:</strong>
                                <InputNumber
                                  value={req.weight}
                                  onChange={(value) => handleUpdateResourceRequirement(index, { weight: value || 1 })}
                                  min={0}
                                  max={1}
                                  step={0.1}
                                  style={{ width: '100%' }}
                                />
                              </div>
                            </Col>
                            <Col span={4}>
                              <div>
                                <strong>Min Value:</strong>
                                <InputNumber
                                  value={req.minValue}
                                  onChange={(value) => handleUpdateResourceRequirement(index, { minValue: value || 0 })}
                                  min={0}
                                  max={1}
                                  step={0.1}
                                  style={{ width: '100%' }}
                                />
                              </div>
                            </Col>
                          </Row>
                          {req.resourceId === 'ore_any' && (
                            <div style={{ marginTop: 8 }}>
                              <strong>Any Of:</strong>
                              <Select
                                mode="multiple"
                                value={req.anyOf || []}
                                onChange={(value) => handleUpdateResourceRequirement(index, { anyOf: value })}
                                style={{ width: '100%' }}
                                placeholder="Select ore types this can match"
                              >
                                {NATURAL_RESOURCE_IDS.filter(id => id.includes('ore') || id === 'coal').map(id => (
                                  <Select.Option key={id} value={id}>{id.replace('_', ' ')}</Select.Option>
                                ))}
                              </Select>
                            </div>
                          )}
                        </Card>
                      ))}

                      {(placementConstraints.requiredResources || []).length === 0 && (
                        <div style={{ textAlign: 'center', padding: '20px', color: '#999' }}>
                          No resource requirements defined. Add resources that this building requires.
                        </div>
                      )}
                    </>
                  )}

                  {!placementConstraints.enabled && (
                    <div style={{ textAlign: 'center', padding: '20px', color: '#999' }}>
                      Placement constraints are disabled. Enable to configure resource requirements.
                    </div>
                  )}
                </Card>
              </div>
            </TabPane>
          </Tabs>
        </Modal>
      </div>
    </>
  );
};

export default BuildingTypeManager;
