import { useState, useEffect } from 'react';
import { Card, Form, InputNumber, Button, message, Divider, Row, Col, Typography, Input, ColorPicker, Slider, Table, Alert } from 'antd';
import { SaveOutlined, ReloadOutlined, InfoCircleOutlined } from '@ant-design/icons';
import type { LandConfig, IntendedRole } from '../types';
import { loadLandConfig, saveLandConfig } from '../api';
import type { Color } from 'antd/es/color-picker';

const { Title, Text, Paragraph } = Typography;

// Default land config if file doesn't exist
const DEFAULT_LAND_CONFIG: LandConfig = {
  version: '1.0.0',
  gridSettings: {
    plotWidth: 100,
    plotHeight: 100,
    worldWidth: 3200,
    worldHeight: 2400
  },
  pricing: {
    basePlotPrice: 100,
    locationMultipliers: {
      center: 1.5,
      edge: 0.8,
      'river-adjacent': 1.3,
      'mountain-adjacent': 0.7
    },
    terrainMultipliers: {
      fertile: 1.4,
      rocky: 0.6,
      sandy: 0.8,
      forested: 1.1
    }
  },
  immigrationRequirements: {
    wealthy: { minPlots: 4, maxPlots: 10, description: 'Wealthy immigrants require significant land holdings' },
    merchant: { minPlots: 2, maxPlots: 4, description: 'Merchants need land for business premises' },
    craftsman: { minPlots: 0, maxPlots: 1, description: 'Craftsmen can rent or own small plots' },
    laborer: { minPlots: 0, maxPlots: 0, description: 'Laborers typically rent housing' }
  },
  overlayColors: {
    townOwned: '#4a90d9',
    citizenOwned: '#52c41a',
    forSale: '#faad14',
    gridLines: '#444444',
    gridLinesOpacity: 0.3
  }
};

const LandConfigManager: React.FC = () => {
  const [data, setData] = useState<LandConfig | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const configData = await loadLandConfig();
      setData(configData);
      form.setFieldsValue(configData);
    } catch (error) {
      console.warn('Could not load land_config.json, using defaults:', error);
      setData(DEFAULT_LAND_CONFIG);
      form.setFieldsValue(DEFAULT_LAND_CONFIG);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);

      const newData: LandConfig = {
        ...values,
        version: data?.version || '1.0.0'
      };

      await saveLandConfig(newData);
      setData(newData);
      message.success('Land configuration saved successfully');
    } catch (error) {
      message.error('Failed to save land configuration');
      console.error(error);
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    if (data) {
      form.setFieldsValue(data);
      message.info('Form reset to last saved values');
    }
  };

  // Calculate grid stats
  const calculateGridStats = () => {
    const values = form.getFieldsValue();
    const gs = values.gridSettings || DEFAULT_LAND_CONFIG.gridSettings;
    const plotsX = Math.floor((gs.worldWidth || 3200) / (gs.plotWidth || 100));
    const plotsY = Math.floor((gs.worldHeight || 2400) / (gs.plotHeight || 100));
    return {
      plotsX,
      plotsY,
      totalPlots: plotsX * plotsY
    };
  };

  const gridStats = calculateGridStats();

  const immigrationColumns = [
    {
      title: 'Role',
      dataIndex: 'role',
      key: 'role',
      render: (role: string) => <Text strong style={{ textTransform: 'capitalize' }}>{role}</Text>
    },
    {
      title: 'Min Plots',
      dataIndex: 'minPlots',
      key: 'minPlots',
      render: (_: number, record: { role: IntendedRole }) => (
        <Form.Item
          name={['immigrationRequirements', record.role, 'minPlots']}
          style={{ margin: 0 }}
        >
          <InputNumber min={0} max={20} />
        </Form.Item>
      )
    },
    {
      title: 'Max Plots',
      dataIndex: 'maxPlots',
      key: 'maxPlots',
      render: (_: number, record: { role: IntendedRole }) => (
        <Form.Item
          name={['immigrationRequirements', record.role, 'maxPlots']}
          style={{ margin: 0 }}
        >
          <InputNumber min={0} max={50} />
        </Form.Item>
      )
    },
    {
      title: 'Description',
      dataIndex: 'description',
      key: 'description',
      render: (_: string, record: { role: IntendedRole }) => (
        <Form.Item
          name={['immigrationRequirements', record.role, 'description']}
          style={{ margin: 0 }}
        >
          <Input />
        </Form.Item>
      )
    }
  ];

  const immigrationData: { role: IntendedRole }[] = [
    { role: 'wealthy' },
    { role: 'merchant' },
    { role: 'craftsman' },
    { role: 'laborer' }
  ];

  if (loading) {
    return <Card loading={true} />;
  }

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>
            Land System Configuration
          </Title>
          <div>
            <Button
              icon={<ReloadOutlined />}
              onClick={handleReset}
              style={{ marginRight: 8 }}
            >
              Reset
            </Button>
            <Button
              type="primary"
              icon={<SaveOutlined />}
              onClick={handleSave}
              loading={saving}
            >
              Save
            </Button>
          </div>
        </div>

        <Alert
          message="Land System Overview"
          description="The land system divides the world into a grid of purchasable plots. Citizens can buy, sell, and develop land. Land ownership affects immigration eligibility and emergent social class."
          type="info"
          showIcon
          icon={<InfoCircleOutlined />}
          style={{ marginBottom: 24 }}
        />

        <Form
          form={form}
          layout="vertical"
          initialValues={data || DEFAULT_LAND_CONFIG}
          onValuesChange={() => {
            // Trigger re-calculation of grid stats
            form.validateFields();
          }}
        >
          <Divider orientation="left">Grid Settings</Divider>

          <Row gutter={24}>
            <Col span={6}>
              <Form.Item
                name={['gridSettings', 'plotWidth']}
                label="Plot Width (pixels)"
              >
                <InputNumber min={50} max={500} step={10} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['gridSettings', 'plotHeight']}
                label="Plot Height (pixels)"
              >
                <InputNumber min={50} max={500} step={10} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['gridSettings', 'worldWidth']}
                label="World Width"
              >
                <InputNumber min={1000} max={10000} step={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['gridSettings', 'worldHeight']}
                label="World Height"
              >
                <InputNumber min={1000} max={10000} step={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Card size="small" style={{ marginBottom: 24 }}>
            <Row gutter={16}>
              <Col span={8}>
                <Text strong>Grid Size: </Text>
                <Text>{gridStats.plotsX} x {gridStats.plotsY} plots</Text>
              </Col>
              <Col span={8}>
                <Text strong>Total Plots: </Text>
                <Text>{gridStats.totalPlots.toLocaleString()}</Text>
              </Col>
              <Col span={8}>
                <Text strong>Plot Area: </Text>
                <Text>{(form.getFieldValue(['gridSettings', 'plotWidth']) || 100) * (form.getFieldValue(['gridSettings', 'plotHeight']) || 100)} px²</Text>
              </Col>
            </Row>
          </Card>

          <Divider orientation="left">Pricing</Divider>

          <Row gutter={24}>
            <Col span={8}>
              <Form.Item
                name={['pricing', 'basePlotPrice']}
                label="Base Plot Price (Gold)"
              >
                <InputNumber
                  min={1}
                  step={10}
                  style={{ width: '100%' }}
                  formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                  parser={value => Number(value?.replace(/,/g, '') || 0)}
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={24}>
            <Col span={12}>
              <Card size="small" title="Location Multipliers">
                <Paragraph type="secondary">
                  Price multipliers based on plot location in the world.
                </Paragraph>
                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'locationMultipliers', 'center']}
                      label="Center"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'locationMultipliers', 'edge']}
                      label="Edge"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'locationMultipliers', 'river-adjacent']}
                      label="River Adjacent"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'locationMultipliers', 'mountain-adjacent']}
                      label="Mountain Adjacent"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                </Row>
              </Card>
            </Col>
            <Col span={12}>
              <Card size="small" title="Terrain Multipliers">
                <Paragraph type="secondary">
                  Price multipliers based on terrain type.
                </Paragraph>
                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'terrainMultipliers', 'fertile']}
                      label="Fertile"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'terrainMultipliers', 'rocky']}
                      label="Rocky"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'terrainMultipliers', 'sandy']}
                      label="Sandy"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item
                      name={['pricing', 'terrainMultipliers', 'forested']}
                      label="Forested"
                    >
                      <InputNumber min={0.1} max={5} step={0.1} style={{ width: '100%' }} />
                    </Form.Item>
                  </Col>
                </Row>
              </Card>
            </Col>
          </Row>

          <Divider orientation="left" style={{ marginTop: 24 }}>Immigration Land Requirements</Divider>
          <Paragraph type="secondary">
            Defines how many land plots each immigrant role must purchase to be accepted into the town.
          </Paragraph>

          <Table
            dataSource={immigrationData}
            columns={immigrationColumns}
            pagination={false}
            rowKey="role"
            size="small"
          />

          <Divider orientation="left" style={{ marginTop: 24 }}>Overlay Colors</Divider>
          <Paragraph type="secondary">
            Colors used for the land ownership overlay in the game.
          </Paragraph>

          <Row gutter={24}>
            <Col span={6}>
              <Form.Item
                name={['overlayColors', 'townOwned']}
                label="Town Owned"
                getValueFromEvent={(color: Color) => color.toHexString()}
              >
                <ColorPicker format="hex" showText />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['overlayColors', 'citizenOwned']}
                label="Citizen Owned"
                getValueFromEvent={(color: Color) => color.toHexString()}
              >
                <ColorPicker format="hex" showText />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['overlayColors', 'forSale']}
                label="For Sale"
                getValueFromEvent={(color: Color) => color.toHexString()}
              >
                <ColorPicker format="hex" showText />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name={['overlayColors', 'gridLines']}
                label="Grid Lines"
                getValueFromEvent={(color: Color) => color.toHexString()}
              >
                <ColorPicker format="hex" showText />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={24}>
            <Col span={8}>
              <Form.Item
                name={['overlayColors', 'gridLinesOpacity']}
                label="Grid Lines Opacity"
              >
                <Slider min={0} max={1} step={0.1} marks={{ 0: '0%', 0.5: '50%', 1: '100%' }} />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Card>
    </div>
  );
};

export default LandConfigManager;
