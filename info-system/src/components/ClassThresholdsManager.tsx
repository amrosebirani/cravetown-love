import { useState, useEffect } from 'react';
import { Card, Form, InputNumber, Button, message, Divider, Row, Col, Typography, Slider, Tooltip, Alert } from 'antd';
import { SaveOutlined, ReloadOutlined, InfoCircleOutlined } from '@ant-design/icons';
import type { ClassThresholds } from '../types';
import { loadClassThresholds, saveClassThresholds } from '../api';

const { Title, Text, Paragraph } = Typography;

// Default thresholds if file doesn't exist
const DEFAULT_THRESHOLDS: ClassThresholds = {
  version: '1.0.0',
  description: 'Emergent class thresholds based on net worth and capital ratio',
  netWorthThresholds: {
    elite: { min: 10000 },
    upper: { min: 3000, max: 9999 },
    middle: { min: 500, max: 2999 },
    lower: { max: 499 }
  },
  capitalRatioThresholds: {
    elite: 0.7,
    upper: 0.5,
    middle: 0.3
  }
};

const ClassThresholdsManager: React.FC = () => {
  const [data, setData] = useState<ClassThresholds | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const thresholdsData = await loadClassThresholds();
      setData(thresholdsData);
      form.setFieldsValue(thresholdsData);
    } catch (error) {
      console.warn('Could not load class_thresholds.json, using defaults:', error);
      setData(DEFAULT_THRESHOLDS);
      form.setFieldsValue(DEFAULT_THRESHOLDS);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);

      const newData: ClassThresholds = {
        ...data,
        ...values,
        version: data?.version || '1.0.0'
      };

      await saveClassThresholds(newData);
      setData(newData);
      message.success('Class thresholds saved successfully');
    } catch (error) {
      message.error('Failed to save class thresholds');
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

  // Calculate class from sample values for preview
  const getClassFromSample = (netWorth: number, capitalRatio: number): string => {
    const values = form.getFieldsValue();
    const nw = values.netWorthThresholds;
    const cr = values.capitalRatioThresholds;

    if (netWorth >= (nw?.elite?.min || 10000) && capitalRatio >= (cr?.elite || 0.7)) {
      return 'elite';
    } else if (netWorth >= (nw?.upper?.min || 3000) && capitalRatio >= (cr?.upper || 0.5)) {
      return 'upper';
    } else if (netWorth >= (nw?.middle?.min || 500) && capitalRatio >= (cr?.middle || 0.3)) {
      return 'middle';
    }
    return 'lower';
  };

  const classColors: Record<string, string> = {
    elite: '#722ed1',
    upper: '#1890ff',
    middle: '#52c41a',
    lower: '#8c8c8c'
  };

  if (loading) {
    return <Card loading={true} />;
  }

  return (
    <div>
      <Card>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
          <Title level={3} style={{ margin: 0 }}>
            Emergent Class Thresholds
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
          message="About Emergent Class System"
          description="Citizens are NOT assigned a class at creation. Instead, their class is calculated dynamically based on their accumulated wealth (net worth) and the ratio of capital income to total income. This creates realistic social mobility."
          type="info"
          showIcon
          icon={<InfoCircleOutlined />}
          style={{ marginBottom: 24 }}
        />

        <Form
          form={form}
          layout="vertical"
          initialValues={data || DEFAULT_THRESHOLDS}
        >
          <Divider orientation="left">Net Worth Thresholds (Gold)</Divider>
          <Paragraph type="secondary">
            Minimum gold holdings required to qualify for each class tier.
          </Paragraph>

          <Row gutter={24}>
            <Col span={6}>
              <Card size="small" style={{ borderColor: classColors.elite }}>
                <Title level={5} style={{ color: classColors.elite }}>Elite</Title>
                <Form.Item
                  name={['netWorthThresholds', 'elite', 'min']}
                  label="Minimum Net Worth"
                >
                  <InputNumber
                    min={0}
                    step={1000}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
                <Text type="secondary">No maximum (top tier)</Text>
              </Card>
            </Col>
            <Col span={6}>
              <Card size="small" style={{ borderColor: classColors.upper }}>
                <Title level={5} style={{ color: classColors.upper }}>Upper</Title>
                <Form.Item
                  name={['netWorthThresholds', 'upper', 'min']}
                  label="Minimum"
                >
                  <InputNumber
                    min={0}
                    step={500}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
                <Form.Item
                  name={['netWorthThresholds', 'upper', 'max']}
                  label="Maximum"
                >
                  <InputNumber
                    min={0}
                    step={500}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
              </Card>
            </Col>
            <Col span={6}>
              <Card size="small" style={{ borderColor: classColors.middle }}>
                <Title level={5} style={{ color: classColors.middle }}>Middle</Title>
                <Form.Item
                  name={['netWorthThresholds', 'middle', 'min']}
                  label="Minimum"
                >
                  <InputNumber
                    min={0}
                    step={100}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
                <Form.Item
                  name={['netWorthThresholds', 'middle', 'max']}
                  label="Maximum"
                >
                  <InputNumber
                    min={0}
                    step={100}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
              </Card>
            </Col>
            <Col span={6}>
              <Card size="small" style={{ borderColor: classColors.lower }}>
                <Title level={5} style={{ color: classColors.lower }}>Lower</Title>
                <Text type="secondary">No minimum (base tier)</Text>
                <Form.Item
                  name={['netWorthThresholds', 'lower', 'max']}
                  label="Maximum"
                  style={{ marginTop: 24 }}
                >
                  <InputNumber
                    min={0}
                    step={100}
                    style={{ width: '100%' }}
                    formatter={value => `${value}`.replace(/\B(?=(\d{3})+(?!\d))/g, ',')}
                    parser={value => Number(value?.replace(/,/g, '') || 0)}
                  />
                </Form.Item>
              </Card>
            </Col>
          </Row>

          <Divider orientation="left" style={{ marginTop: 32 }}>Capital Ratio Thresholds</Divider>
          <Paragraph type="secondary">
            Capital ratio = (passive income + rent income) / total income. Higher ratios indicate wealth comes from
            capital (land, buildings, investments) rather than labor. This distinguishes merchants from craftsmen
            even at similar wealth levels.
          </Paragraph>

          <Row gutter={24}>
            <Col span={8}>
              <Card size="small" style={{ borderColor: classColors.elite }}>
                <Title level={5} style={{ color: classColors.elite }}>Elite Capital Ratio</Title>
                <Form.Item
                  name={['capitalRatioThresholds', 'elite']}
                  label={
                    <Tooltip title="Minimum capital ratio required (in addition to net worth) to be classified as Elite">
                      Minimum Ratio <InfoCircleOutlined />
                    </Tooltip>
                  }
                >
                  <Slider
                    min={0}
                    max={1}
                    step={0.05}
                    marks={{ 0: '0%', 0.5: '50%', 1: '100%' }}
                  />
                </Form.Item>
              </Card>
            </Col>
            <Col span={8}>
              <Card size="small" style={{ borderColor: classColors.upper }}>
                <Title level={5} style={{ color: classColors.upper }}>Upper Capital Ratio</Title>
                <Form.Item
                  name={['capitalRatioThresholds', 'upper']}
                  label={
                    <Tooltip title="Minimum capital ratio required (in addition to net worth) to be classified as Upper">
                      Minimum Ratio <InfoCircleOutlined />
                    </Tooltip>
                  }
                >
                  <Slider
                    min={0}
                    max={1}
                    step={0.05}
                    marks={{ 0: '0%', 0.5: '50%', 1: '100%' }}
                  />
                </Form.Item>
              </Card>
            </Col>
            <Col span={8}>
              <Card size="small" style={{ borderColor: classColors.middle }}>
                <Title level={5} style={{ color: classColors.middle }}>Middle Capital Ratio</Title>
                <Form.Item
                  name={['capitalRatioThresholds', 'middle']}
                  label={
                    <Tooltip title="Minimum capital ratio required (in addition to net worth) to be classified as Middle">
                      Minimum Ratio <InfoCircleOutlined />
                    </Tooltip>
                  }
                >
                  <Slider
                    min={0}
                    max={1}
                    step={0.05}
                    marks={{ 0: '0%', 0.5: '50%', 1: '100%' }}
                  />
                </Form.Item>
              </Card>
            </Col>
          </Row>

          <Divider orientation="left" style={{ marginTop: 32 }}>Class Preview Calculator</Divider>
          <Paragraph type="secondary">
            Enter sample values to see how citizens would be classified:
          </Paragraph>

          <Row gutter={24}>
            <Col span={8}>
              <Form.Item label="Sample Net Worth">
                <InputNumber
                  id="sampleNetWorth"
                  min={0}
                  defaultValue={1500}
                  style={{ width: '100%' }}
                  onChange={() => {
                    // Force re-render to update preview
                    form.validateFields();
                  }}
                />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Sample Capital Ratio">
                <Slider
                  id="sampleCapitalRatio"
                  min={0}
                  max={1}
                  step={0.05}
                  defaultValue={0.4}
                  marks={{ 0: '0%', 0.5: '50%', 1: '100%' }}
                />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Card size="small">
                <Text strong>Resulting Class: </Text>
                <Text style={{
                  color: classColors[getClassFromSample(1500, 0.4)],
                  fontWeight: 'bold',
                  fontSize: 16
                }}>
                  {getClassFromSample(1500, 0.4).toUpperCase()}
                </Text>
              </Card>
            </Col>
          </Row>
        </Form>
      </Card>
    </div>
  );
};

export default ClassThresholdsManager;
