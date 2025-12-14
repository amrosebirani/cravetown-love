import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Space, message, Tag, Row, Col, Typography, Slider, Divider, Alert } from 'antd';
import { EditOutlined, EyeOutlined, HomeOutlined, InfoCircleOutlined } from '@ant-design/icons';
import type { BuildingTypesData, BuildingType, HousingConfig, QualityTier } from '../types';
import { loadBuildingTypes, saveBuildingTypes } from '../api';

const { Title, Text, Paragraph } = Typography;

// Quality tier colors
const QUALITY_COLORS: Record<QualityTier, string> = {
  poor: '#8b6914',
  basic: '#6b6b6b',
  good: '#2d862d',
  luxury: '#cc9900',
  masterwork: '#8b2d8b'
};

// Class colors for display
const CLASS_COLORS: Record<string, string> = {
  elite: '#722ed1',
  upper: '#1890ff',
  middle: '#52c41a',
  lower: '#8c8c8c'
};

// Default housing config for new housing buildings
const DEFAULT_HOUSING_CONFIG: HousingConfig = {
  capacity: 4,
  unitsCount: 1,
  housingQuality: 0.5,
  qualityTier: 'basic',
  rentPerOccupant: 10,
  targetClasses: ['middle'],
  acceptableClasses: ['lower', 'middle']
};

const HousingConfigManager: React.FC = () => {
  const [data, setData] = useState<BuildingTypesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<BuildingType | null>(null);
  const [viewing, setViewing] = useState<BuildingType | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isViewModalVisible, setIsViewModalVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const buildingData = await loadBuildingTypes();
      setData(buildingData);
    } catch (error) {
      message.error('Failed to load building types');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: BuildingTypesData) => {
    try {
      await saveBuildingTypes(newData);
      setData(newData);
      message.success('Housing configuration saved successfully');
    } catch (error) {
      message.error('Failed to save housing configuration');
      console.error(error);
    }
  };

  // Filter to only show housing buildings (category === 'housing')
  const housingBuildings = data?.buildingTypes.filter(b => b.category === 'housing') || [];

  const handleEdit = (record: BuildingType) => {
    setEditing(record);
    // Get existing housing config or use defaults
    const existingConfig = (record as any).housingConfig || DEFAULT_HOUSING_CONFIG;
    form.setFieldsValue({
      ...record,
      housingConfig: existingConfig
    });
    setIsModalVisible(true);
  };

  const handleView = (record: BuildingType) => {
    setViewing(record);
    setIsViewModalVisible(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();

      if (!data || !editing) return;

      // Update the building type with housing config
      const updatedBuildings = data.buildingTypes.map(b => {
        if (b.id === editing.id) {
          return {
            ...b,
            housingConfig: values.housingConfig
          };
        }
        return b;
      });

      await saveData({ buildingTypes: updatedBuildings });
      setIsModalVisible(false);
      setEditing(null);
      form.resetFields();
    } catch (error) {
      message.error('Failed to save housing configuration');
      console.error(error);
    }
  };

  const columns = [
    {
      title: 'Building',
      key: 'building',
      render: (_: unknown, record: BuildingType) => (
        <Space>
          <HomeOutlined style={{ color: `rgb(${record.color.map(c => Math.floor(c * 255)).join(',')})` }} />
          <div>
            <div style={{ fontWeight: 'bold' }}>{record.name}</div>
            <Text type="secondary" style={{ fontSize: 12 }}>{record.id}</Text>
          </div>
        </Space>
      )
    },
    {
      title: 'Capacity',
      key: 'capacity',
      width: 100,
      render: (_: unknown, record: BuildingType) => {
        const config = (record as any).housingConfig;
        return config?.capacity || '-';
      }
    },
    {
      title: 'Quality',
      key: 'quality',
      width: 150,
      render: (_: unknown, record: BuildingType) => {
        const config = (record as any).housingConfig as HousingConfig | undefined;
        if (!config) return <Tag>Not Configured</Tag>;
        return (
          <Space direction="vertical" size={0}>
            <Tag color={QUALITY_COLORS[config.qualityTier]}>{config.qualityTier}</Tag>
            <Text type="secondary" style={{ fontSize: 11 }}>
              {Math.round(config.housingQuality * 100)}% quality
            </Text>
          </Space>
        );
      }
    },
    {
      title: 'Rent',
      key: 'rent',
      width: 100,
      render: (_: unknown, record: BuildingType) => {
        const config = (record as any).housingConfig as HousingConfig | undefined;
        return config?.rentPerOccupant ? `${config.rentPerOccupant} gold` : '-';
      }
    },
    {
      title: 'Target Classes',
      key: 'classes',
      render: (_: unknown, record: BuildingType) => {
        const config = (record as any).housingConfig as HousingConfig | undefined;
        if (!config?.targetClasses?.length) return '-';
        return (
          <Space size={4} wrap>
            {config.targetClasses.map(cls => (
              <Tag key={cls} color={CLASS_COLORS[cls] || '#888'}>{cls}</Tag>
            ))}
          </Space>
        );
      }
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      render: (_: unknown, record: BuildingType) => (
        <Space>
          <Button
            type="link"
            icon={<EyeOutlined />}
            onClick={() => handleView(record)}
          />
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record)}
          />
        </Space>
      )
    }
  ];

  if (loading) {
    return <Card loading={true} />;
  }

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>
            Housing Configuration
          </Title>
        </div>

        <Alert
          message="Housing Buildings"
          description="This page shows all buildings with category 'housing'. Configure housing-specific properties like capacity, quality tier, rent rates, and target social classes."
          type="info"
          showIcon
          icon={<InfoCircleOutlined />}
          style={{ marginBottom: 24 }}
        />

        {housingBuildings.length === 0 ? (
          <Alert
            message="No Housing Buildings Found"
            description="No buildings with category 'housing' exist in building_types.json. Create housing buildings in the Building Types manager first."
            type="warning"
            showIcon
          />
        ) : (
          <Table
            columns={columns}
            dataSource={housingBuildings}
            rowKey="id"
            pagination={false}
          />
        )}
      </Card>

      {/* Edit Modal */}
      <Modal
        title={`Configure Housing: ${editing?.name}`}
        open={isModalVisible}
        onOk={handleSave}
        onCancel={() => {
          setIsModalVisible(false);
          setEditing(null);
          form.resetFields();
        }}
        width={700}
        okText="Save"
      >
        <Form
          form={form}
          layout="vertical"
        >
          <Divider orientation="left">Capacity</Divider>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'capacity']}
                label="Max Occupants"
                rules={[{ required: true, message: 'Capacity is required' }]}
                tooltip="Maximum number of people who can live in this building"
              >
                <InputNumber min={1} max={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'unitsCount']}
                label="Units/Apartments"
                tooltip="Number of separate living units (for multi-family buildings)"
              >
                <InputNumber min={1} max={50} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Divider orientation="left">Quality</Divider>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'qualityTier']}
                label="Quality Tier"
                rules={[{ required: true, message: 'Quality tier is required' }]}
              >
                <Select>
                  <Select.Option value="poor">
                    <Tag color={QUALITY_COLORS.poor}>Poor</Tag> - Basic shelter
                  </Select.Option>
                  <Select.Option value="basic">
                    <Tag color={QUALITY_COLORS.basic}>Basic</Tag> - Standard housing
                  </Select.Option>
                  <Select.Option value="good">
                    <Tag color={QUALITY_COLORS.good}>Good</Tag> - Comfortable
                  </Select.Option>
                  <Select.Option value="luxury">
                    <Tag color={QUALITY_COLORS.luxury}>Luxury</Tag> - High-end
                  </Select.Option>
                  <Select.Option value="masterwork">
                    <Tag color={QUALITY_COLORS.masterwork}>Masterwork</Tag> - Exceptional
                  </Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'housingQuality']}
                label="Quality Score (0-1)"
                tooltip="Numeric quality score used for satisfaction calculations"
              >
                <Slider
                  min={0}
                  max={1}
                  step={0.05}
                  marks={{ 0: '0%', 0.5: '50%', 1: '100%' }}
                />
              </Form.Item>
            </Col>
          </Row>

          <Divider orientation="left">Economics</Divider>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'rentPerOccupant']}
                label="Rent per Occupant (Gold/cycle)"
                rules={[{ required: true, message: 'Rent is required' }]}
              >
                <InputNumber min={0} step={5} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Divider orientation="left">Class Restrictions</Divider>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'targetClasses']}
                label="Target Classes"
                tooltip="Social classes this housing is designed for"
              >
                <Select mode="multiple" placeholder="Select target classes">
                  <Select.Option value="lower"><Tag color={CLASS_COLORS.lower}>Lower</Tag></Select.Option>
                  <Select.Option value="middle"><Tag color={CLASS_COLORS.middle}>Middle</Tag></Select.Option>
                  <Select.Option value="upper"><Tag color={CLASS_COLORS.upper}>Upper</Tag></Select.Option>
                  <Select.Option value="elite"><Tag color={CLASS_COLORS.elite}>Elite</Tag></Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'acceptableClasses']}
                label="Acceptable Classes"
                tooltip="All classes that CAN live here (may be broader than target)"
              >
                <Select mode="multiple" placeholder="Select acceptable classes">
                  <Select.Option value="lower"><Tag color={CLASS_COLORS.lower}>Lower</Tag></Select.Option>
                  <Select.Option value="middle"><Tag color={CLASS_COLORS.middle}>Middle</Tag></Select.Option>
                  <Select.Option value="upper"><Tag color={CLASS_COLORS.upper}>Upper</Tag></Select.Option>
                  <Select.Option value="elite"><Tag color={CLASS_COLORS.elite}>Elite</Tag></Select.Option>
                </Select>
              </Form.Item>
            </Col>
          </Row>

          <Divider orientation="left">Upgrade Path (Optional)</Divider>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name={['housingConfig', 'upgradeableTo']}
                label="Can Upgrade To"
                tooltip="Building type ID this housing can be upgraded to"
              >
                <Select allowClear placeholder="Select upgrade building">
                  {housingBuildings
                    .filter(b => b.id !== editing?.id)
                    .map(b => (
                      <Select.Option key={b.id} value={b.id}>{b.name}</Select.Option>
                    ))}
                </Select>
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Modal>

      {/* View Modal */}
      <Modal
        title={`Housing Details: ${viewing?.name}`}
        open={isViewModalVisible}
        onCancel={() => {
          setIsViewModalVisible(false);
          setViewing(null);
        }}
        footer={null}
        width={600}
      >
        {viewing && (
          <div>
            <Row gutter={[16, 16]}>
              <Col span={12}>
                <Text strong>Building ID:</Text>
                <div>{viewing.id}</div>
              </Col>
              <Col span={12}>
                <Text strong>Category:</Text>
                <div>{viewing.category}</div>
              </Col>
            </Row>

            <Divider />

            {(viewing as any).housingConfig ? (
              <>
                <Row gutter={[16, 16]}>
                  <Col span={8}>
                    <Text strong>Capacity:</Text>
                    <div>{((viewing as any).housingConfig as HousingConfig).capacity} occupants</div>
                  </Col>
                  <Col span={8}>
                    <Text strong>Units:</Text>
                    <div>{((viewing as any).housingConfig as HousingConfig).unitsCount || 1}</div>
                  </Col>
                  <Col span={8}>
                    <Text strong>Rent:</Text>
                    <div>{((viewing as any).housingConfig as HousingConfig).rentPerOccupant} gold/cycle</div>
                  </Col>
                </Row>

                <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
                  <Col span={12}>
                    <Text strong>Quality Tier:</Text>
                    <div>
                      <Tag color={QUALITY_COLORS[((viewing as any).housingConfig as HousingConfig).qualityTier]}>
                        {((viewing as any).housingConfig as HousingConfig).qualityTier}
                      </Tag>
                    </div>
                  </Col>
                  <Col span={12}>
                    <Text strong>Quality Score:</Text>
                    <div>{Math.round(((viewing as any).housingConfig as HousingConfig).housingQuality * 100)}%</div>
                  </Col>
                </Row>

                <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
                  <Col span={12}>
                    <Text strong>Target Classes:</Text>
                    <div>
                      <Space wrap>
                        {((viewing as any).housingConfig as HousingConfig).targetClasses?.map(cls => (
                          <Tag key={cls} color={CLASS_COLORS[cls]}>{cls}</Tag>
                        ))}
                      </Space>
                    </div>
                  </Col>
                  <Col span={12}>
                    <Text strong>Acceptable Classes:</Text>
                    <div>
                      <Space wrap>
                        {((viewing as any).housingConfig as HousingConfig).acceptableClasses?.map(cls => (
                          <Tag key={cls} color={CLASS_COLORS[cls]}>{cls}</Tag>
                        ))}
                      </Space>
                    </div>
                  </Col>
                </Row>
              </>
            ) : (
              <Alert
                message="Housing Not Configured"
                description="This building does not have housing configuration. Click Edit to configure it."
                type="warning"
              />
            )}
          </div>
        )}
      </Modal>
    </div>
  );
};

export default HousingConfigManager;
