import { useState, useEffect } from 'react';
import {
  Table, Button, Space, message, Popconfirm, Modal, Form, Input, Select,
  InputNumber, Row, Col, Card, Tabs, Divider, Tag, Slider, Switch
} from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { NaturalResource, NaturalResourcesData, PerlinDistribution, ClusterDistribution } from '../types';
import { loadNaturalResources, saveNaturalResources } from '../api';
import { RESOURCE_CATEGORIES, DISTRIBUTION_TYPES, RESOURCE_COLORS } from '../constants';

const { TabPane } = Tabs;

const NaturalResourceManager = () => {
  const [resources, setResources] = useState<NaturalResource[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingResource, setEditingResource] = useState<NaturalResource | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [form] = Form.useForm();
  const [searchText, setSearchText] = useState('');
  const [distributionType, setDistributionType] = useState<'perlin_hybrid' | 'regional_cluster'>('perlin_hybrid');

  useEffect(() => {
    loadResourcesList();
  }, []);

  const loadResourcesList = async () => {
    setLoading(true);
    try {
      const data = await loadNaturalResources();
      setResources(data.naturalResources);
      messageApi.success('Natural resources loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load natural resources: ${error}`);
      console.error('Failed to load natural resources:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveResourcesList = async (updatedResources: NaturalResource[]) => {
    try {
      const data: NaturalResourcesData = {
        version: '1.0.0',
        naturalResources: updatedResources
      };
      await saveNaturalResources(data);
      setResources(updatedResources);
      messageApi.success('Natural resources saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save natural resources: ${error}`);
      console.error('Failed to save natural resources:', error);
    }
  };

  const getDefaultPerlinDistribution = (): PerlinDistribution => ({
    type: 'perlin_hybrid',
    perlinWeight: 0.6,
    hotspotWeight: 0.4,
    frequency: 0.01,
    octaves: 3,
    persistence: 0.5,
    hotspotCount: [2, 4],
    hotspotRadius: [150, 300],
    hotspotIntensity: [0.6, 1.0]
  });

  const getDefaultClusterDistribution = (): ClusterDistribution => ({
    type: 'regional_cluster',
    depositCount: [2, 4],
    depositRadius: [60, 120],
    centerRichness: [0.7, 1.0],
    falloffExponent: 2,
    noiseVariation: 0.1
  });

  const handleAddResource = () => {
    const defaultColor = RESOURCE_COLORS.ground_water || [0.5, 0.5, 0.5];
    const newResource: NaturalResource = {
      id: 'new_resource',
      name: 'New Resource',
      category: 'continuous',
      description: '',
      distribution: getDefaultPerlinDistribution(),
      visualization: {
        color: defaultColor,
        opacity: 0.6,
        showThreshold: 0.1
      }
    };

    setEditingResource(newResource);
    setDistributionType('perlin_hybrid');
    form.setFieldsValue({
      id: newResource.id,
      name: newResource.name,
      category: newResource.category,
      description: newResource.description,
      colorR: defaultColor[0],
      colorG: defaultColor[1],
      colorB: defaultColor[2],
      opacity: 0.6,
      showThreshold: 0.1,
      // Perlin fields
      perlinWeight: 0.6,
      hotspotWeight: 0.4,
      frequency: 0.01,
      octaves: 3,
      persistence: 0.5,
      hotspotCountMin: 2,
      hotspotCountMax: 4,
      hotspotRadiusMin: 150,
      hotspotRadiusMax: 300,
      hotspotIntensityMin: 0.6,
      hotspotIntensityMax: 1.0,
      // River influence
      riverInfluenceEnabled: false,
      riverRange: 200,
      riverBoost: 0.3,
    });
    setEditorVisible(true);
  };

  const handleEditResource = (resource: NaturalResource) => {
    setEditingResource({ ...resource });
    const distType = resource.distribution.type;
    setDistributionType(distType);

    const baseFields = {
      id: resource.id,
      name: resource.name,
      category: resource.category,
      description: resource.description || '',
      colorR: resource.visualization.color[0],
      colorG: resource.visualization.color[1],
      colorB: resource.visualization.color[2],
      opacity: resource.visualization.opacity,
      showThreshold: resource.visualization.showThreshold,
      riverInfluenceEnabled: resource.riverInfluence?.enabled || false,
      riverRange: resource.riverInfluence?.range || 200,
      riverBoost: resource.riverInfluence?.boost || 0.3,
    };

    if (distType === 'perlin_hybrid') {
      const dist = resource.distribution as PerlinDistribution;
      form.setFieldsValue({
        ...baseFields,
        perlinWeight: dist.perlinWeight,
        hotspotWeight: dist.hotspotWeight,
        frequency: dist.frequency,
        octaves: dist.octaves,
        persistence: dist.persistence,
        hotspotCountMin: dist.hotspotCount[0],
        hotspotCountMax: dist.hotspotCount[1],
        hotspotRadiusMin: dist.hotspotRadius[0],
        hotspotRadiusMax: dist.hotspotRadius[1],
        hotspotIntensityMin: dist.hotspotIntensity[0],
        hotspotIntensityMax: dist.hotspotIntensity[1],
      });
    } else {
      const dist = resource.distribution as ClusterDistribution;
      form.setFieldsValue({
        ...baseFields,
        depositCountMin: dist.depositCount[0],
        depositCountMax: dist.depositCount[1],
        depositRadiusMin: dist.depositRadius[0],
        depositRadiusMax: dist.depositRadius[1],
        centerRichnessMin: dist.centerRichness[0],
        centerRichnessMax: dist.centerRichness[1],
        falloffExponent: dist.falloffExponent,
        noiseVariation: dist.noiseVariation,
        // Collision rules
        riverDistance: resource.collisionRules?.riverDistance || 100,
        sameTypeDistance: resource.collisionRules?.sameTypeDistance || 150,
        boundaryBuffer: resource.collisionRules?.boundaryBuffer || 50,
      });
    }

    setEditorVisible(true);
  };

  const handleSaveResource = () => {
    form.validateFields().then((values) => {
      const isNew = !resources.find(r => r.id === editingResource?.id);

      const color: [number, number, number] = [
        values.colorR ?? 0.5,
        values.colorG ?? 0.5,
        values.colorB ?? 0.5,
      ];

      let distribution: PerlinDistribution | ClusterDistribution;
      if (distributionType === 'perlin_hybrid') {
        distribution = {
          type: 'perlin_hybrid',
          perlinWeight: values.perlinWeight,
          hotspotWeight: values.hotspotWeight,
          frequency: values.frequency,
          octaves: values.octaves,
          persistence: values.persistence,
          hotspotCount: [values.hotspotCountMin, values.hotspotCountMax],
          hotspotRadius: [values.hotspotRadiusMin, values.hotspotRadiusMax],
          hotspotIntensity: [values.hotspotIntensityMin, values.hotspotIntensityMax],
        };
      } else {
        distribution = {
          type: 'regional_cluster',
          depositCount: [values.depositCountMin, values.depositCountMax],
          depositRadius: [values.depositRadiusMin, values.depositRadiusMax],
          centerRichness: [values.centerRichnessMin, values.centerRichnessMax],
          falloffExponent: values.falloffExponent,
          noiseVariation: values.noiseVariation,
        };
      }

      const resourceData: NaturalResource = {
        id: values.id,
        name: values.name,
        category: values.category,
        description: values.description,
        distribution,
        visualization: {
          color,
          opacity: values.opacity,
          showThreshold: values.showThreshold,
        },
      };

      // Add river influence for continuous resources
      if (values.riverInfluenceEnabled) {
        resourceData.riverInfluence = {
          enabled: true,
          range: values.riverRange,
          boost: values.riverBoost,
        };
      }

      // Add collision rules for discrete resources
      if (distributionType === 'regional_cluster') {
        resourceData.collisionRules = {
          riverDistance: values.riverDistance || 100,
          sameTypeDistance: values.sameTypeDistance || 150,
          boundaryBuffer: values.boundaryBuffer || 50,
        };
      }

      let updatedResources: NaturalResource[];
      if (isNew) {
        updatedResources = [...resources, resourceData];
      } else {
        updatedResources = resources.map(r =>
          r.id === editingResource?.id ? resourceData : r
        );
      }

      saveResourcesList(updatedResources);
      setEditorVisible(false);
      setEditingResource(null);
      form.resetFields();
    });
  };

  const handleDeleteResource = async (id: string) => {
    const updatedResources = resources.filter(r => r.id !== id);
    await saveResourcesList(updatedResources);
  };

  const columns = [
    {
      title: 'Color',
      key: 'color',
      width: 60,
      render: (_: unknown, record: NaturalResource) => (
        <div style={{
          width: 30,
          height: 30,
          backgroundColor: `rgb(${record.visualization.color[0] * 255}, ${record.visualization.color[1] * 255}, ${record.visualization.color[2] * 255})`,
          borderRadius: '4px',
          border: '1px solid #ddd'
        }} />
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
      width: 100,
      render: (category: string) => (
        <Tag color={category === 'continuous' ? 'blue' : 'orange'}>
          {category}
        </Tag>
      ),
    },
    {
      title: 'Distribution',
      key: 'distribution',
      width: 150,
      render: (_: unknown, record: NaturalResource) => (
        <span>{record.distribution.type.replace('_', ' ')}</span>
      ),
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
      render: (_: unknown, record: NaturalResource) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditResource(record)}
          />
          <Popconfirm
            title="Delete this resource?"
            description="This action cannot be undone."
            onConfirm={() => handleDeleteResource(record.id)}
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

  const filteredResources = resources.filter(resource => {
    const searchLower = searchText.toLowerCase();
    return (
      resource.id.toLowerCase().includes(searchLower) ||
      resource.name.toLowerCase().includes(searchLower) ||
      resource.category.toLowerCase().includes(searchLower) ||
      (resource.description && resource.description.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Natural Resources</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddResource}
          >
            Add Resource
          </Button>
        </div>

        <Input
          placeholder="Search resources..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredResources}
          rowKey="id"
          loading={loading}
          scroll={{ x: 900 }}
          pagination={{
            pageSize: 15,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} resources`,
          }}
        />

        <Modal
          title={editingResource && resources.find(r => r.id === editingResource.id) ? 'Edit Resource' : 'Add Resource'}
          open={editorVisible}
          onOk={handleSaveResource}
          onCancel={() => {
            setEditorVisible(false);
            setEditingResource(null);
            form.resetFields();
          }}
          okText="Save"
          width={800}
          style={{ top: 20 }}
          styles={{ body: { maxHeight: 'calc(100vh - 200px)', overflowY: 'auto' } }}
        >
          <Form form={form} layout="vertical" style={{ marginTop: '16px' }}>
            <Tabs defaultActiveKey="basic">
              <TabPane tab="Basic Info" key="basic">
                <Card title="Resource Identity" size="small" style={{ marginBottom: 16 }}>
                  <Row gutter={16}>
                    <Col span={12}>
                      <Form.Item
                        label="Resource ID"
                        name="id"
                        rules={[{ required: true, message: 'ID is required' }]}
                        tooltip="Unique identifier (e.g., 'iron_ore', 'ground_water')"
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
                        <Select onChange={(val) => {
                          if (val === 'continuous') {
                            setDistributionType('perlin_hybrid');
                          } else {
                            setDistributionType('regional_cluster');
                          }
                        }}>
                          {RESOURCE_CATEGORIES.map(cat => (
                            <Select.Option key={cat} value={cat}>{cat}</Select.Option>
                          ))}
                        </Select>
                      </Form.Item>
                    </Col>
                    <Col span={12}>
                      <Form.Item label="Description" name="description">
                        <Input />
                      </Form.Item>
                    </Col>
                  </Row>
                </Card>

                <Card title="Visualization" size="small" style={{ marginBottom: 16 }}>
                  <Row gutter={16}>
                    <Col span={6}>
                      <Form.Item label="Red" name="colorR" rules={[{ required: true }]}>
                        <InputNumber min={0} max={1} step={0.05} style={{ width: '100%' }} />
                      </Form.Item>
                    </Col>
                    <Col span={6}>
                      <Form.Item label="Green" name="colorG" rules={[{ required: true }]}>
                        <InputNumber min={0} max={1} step={0.05} style={{ width: '100%' }} />
                      </Form.Item>
                    </Col>
                    <Col span={6}>
                      <Form.Item label="Blue" name="colorB" rules={[{ required: true }]}>
                        <InputNumber min={0} max={1} step={0.05} style={{ width: '100%' }} />
                      </Form.Item>
                    </Col>
                    <Col span={6}>
                      <Form.Item label="Opacity" name="opacity" rules={[{ required: true }]}>
                        <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                      </Form.Item>
                    </Col>
                  </Row>
                  <Row gutter={16}>
                    <Col span={12}>
                      <Form.Item
                        label="Show Threshold"
                        name="showThreshold"
                        tooltip="Minimum value to display on overlay"
                      >
                        <InputNumber min={0} max={1} step={0.05} style={{ width: '100%' }} />
                      </Form.Item>
                    </Col>
                    <Col span={12}>
                      <div style={{
                        marginTop: 30,
                        padding: '15px',
                        backgroundColor: `rgba(${(form.getFieldValue('colorR') ?? 0.5) * 255}, ${(form.getFieldValue('colorG') ?? 0.5) * 255}, ${(form.getFieldValue('colorB') ?? 0.5) * 255}, ${form.getFieldValue('opacity') ?? 0.6})`,
                        borderRadius: '4px',
                        textAlign: 'center',
                        color: 'white',
                        fontWeight: 'bold',
                        textShadow: '1px 1px 2px black'
                      }}>
                        Color Preview
                      </div>
                    </Col>
                  </Row>
                </Card>
              </TabPane>

              <TabPane tab="Distribution" key="distribution">
                {distributionType === 'perlin_hybrid' ? (
                  <>
                    <Card title="Perlin Noise Settings" size="small" style={{ marginBottom: 16 }}>
                      <Row gutter={16}>
                        <Col span={8}>
                          <Form.Item label="Perlin Weight" name="perlinWeight">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Hotspot Weight" name="hotspotWeight">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Frequency" name="frequency" tooltip="Controls 'blobiness'">
                            <InputNumber min={0.001} max={0.1} step={0.001} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Octaves" name="octaves" tooltip="Number of noise layers">
                            <InputNumber min={1} max={8} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Persistence" name="persistence" tooltip="Amplitude falloff">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                    </Card>

                    <Card title="Hotspot Settings" size="small" style={{ marginBottom: 16 }}>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Count Min" name="hotspotCountMin">
                            <InputNumber min={0} max={10} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Count Max" name="hotspotCountMax">
                            <InputNumber min={1} max={10} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Radius Min" name="hotspotRadiusMin">
                            <InputNumber min={50} max={500} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Radius Max" name="hotspotRadiusMax">
                            <InputNumber min={50} max={500} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Intensity Min" name="hotspotIntensityMin">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Intensity Max" name="hotspotIntensityMax">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                    </Card>

                    <Card title="River Influence" size="small">
                      <Row gutter={16}>
                        <Col span={8}>
                          <Form.Item label="Enabled" name="riverInfluenceEnabled" valuePropName="checked">
                            <Switch />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Range (px)" name="riverRange">
                            <InputNumber min={0} max={500} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Boost" name="riverBoost">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                    </Card>
                  </>
                ) : (
                  <>
                    <Card title="Cluster Settings" size="small" style={{ marginBottom: 16 }}>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Deposit Count Min" name="depositCountMin">
                            <InputNumber min={1} max={10} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Deposit Count Max" name="depositCountMax">
                            <InputNumber min={1} max={10} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Deposit Radius Min" name="depositRadiusMin">
                            <InputNumber min={20} max={300} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Deposit Radius Max" name="depositRadiusMax">
                            <InputNumber min={20} max={300} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Center Richness Min" name="centerRichnessMin">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Center Richness Max" name="centerRichnessMax">
                            <InputNumber min={0} max={1} step={0.1} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                      <Row gutter={16}>
                        <Col span={12}>
                          <Form.Item label="Falloff Exponent" name="falloffExponent" tooltip="Higher = sharper edges">
                            <InputNumber min={1} max={5} step={0.5} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={12}>
                          <Form.Item label="Noise Variation" name="noiseVariation">
                            <InputNumber min={0} max={0.5} step={0.05} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                    </Card>

                    <Card title="Collision Rules" size="small">
                      <Row gutter={16}>
                        <Col span={8}>
                          <Form.Item label="River Distance" name="riverDistance" tooltip="Min distance from river">
                            <InputNumber min={0} max={300} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Same Type Distance" name="sameTypeDistance" tooltip="Min distance between same type deposits">
                            <InputNumber min={50} max={500} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                        <Col span={8}>
                          <Form.Item label="Boundary Buffer" name="boundaryBuffer" tooltip="Distance from map edge">
                            <InputNumber min={0} max={200} style={{ width: '100%' }} />
                          </Form.Item>
                        </Col>
                      </Row>
                    </Card>
                  </>
                )}
              </TabPane>
            </Tabs>
          </Form>
        </Modal>
      </div>
    </>
  );
};

export default NaturalResourceManager;
