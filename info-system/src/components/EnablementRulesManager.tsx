import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, Select, Space, message, Popconfirm, Tag, Row, Col, InputNumber } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined } from '@ant-design/icons';
import type { EnablementRulesData, EnablementRule, DimensionDefinitions } from '../types';
import { loadEnablementRules, saveEnablementRules, loadDimensionDefinitions } from '../api';
import VectorEditor from './VectorEditor';
import VectorVisualization from './VectorVisualization';
import VectorHeatmap from './VectorHeatmap';

const { TextArea } = Input;

const EnablementRulesManager: React.FC = () => {
  const [data, setData] = useState<EnablementRulesData | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDefinitions | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState<EnablementRule | null>(null);
  const [viewing, setViewing] = useState<EnablementRule | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isViewModalVisible, setIsViewModalVisible] = useState(false);
  const [form] = Form.useForm();
  const [triggerType, setTriggerType] = useState<string>('owns_commodity_tag');

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [rulesData, dimensionsData] = await Promise.all([
        loadEnablementRules(),
        loadDimensionDefinitions()
      ]);
      setData(rulesData);
      setDimensions(dimensionsData);
    } catch (error) {
      message.error('Failed to load enablement rules');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: EnablementRulesData) => {
    try {
      await saveEnablementRules(newData);
      setData(newData);
      message.success('Enablement rules saved successfully');
    } catch (error) {
      message.error('Failed to save enablement rules');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setEditing(null);
    setTriggerType('owns_commodity_tag');
    form.resetFields();
    // Set default craving modifier (all 0)
    form.setFieldsValue({
      effect: {
        cravingModifier: {
          coarse: new Array(9).fill(0),
          fine: new Array(50).fill(0),
        },
        permanent: false,
      },
      trigger: {
        type: 'owns_commodity_tag',
      },
    });
    setIsModalVisible(true);
  };

  const handleEdit = (record: EnablementRule) => {
    setEditing(record);
    setTriggerType(record.trigger.type);
    form.setFieldsValue(record);
    setIsModalVisible(true);
  };

  const handleView = (record: EnablementRule) => {
    setViewing(record);
    setIsViewModalVisible(true);
  };

  const handleDelete = (record: EnablementRule) => {
    if (!data) return;

    const newData: EnablementRulesData = {
      ...data,
      rules: data.rules.filter(r => r.id !== record.id),
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      let newRules: EnablementRule[];

      if (editing) {
        // Edit existing
        newRules = data.rules.map(r =>
          r.id === editing.id ? values : r
        );
      } else {
        // Add new
        newRules = [...data.rules, values];
      }

      const newData: EnablementRulesData = {
        ...data,
        rules: newRules,
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const getTriggerColor = (type: string): string => {
    switch (type) {
      case 'owns_commodity_tag': return 'blue';
      case 'has_relationship': return 'green';
      case 'satisfaction_above': return 'cyan';
      case 'satisfaction_below': return 'orange';
      case 'class_change': return 'purple';
      default: return 'default';
    }
  };

  const renderTriggerFields = () => {
    switch (triggerType) {
      case 'owns_commodity_tag':
        return (
          <>
            <Form.Item
              name={['trigger', 'tag']}
              label="Tag"
              rules={[{ required: true, message: 'Please input the tag!' }]}
            >
              <Input placeholder="e.g., shelter, education, precious_metals" />
            </Form.Item>
            <Form.Item
              name={['trigger', 'minQuantity']}
              label="Minimum Quantity"
              rules={[{ required: true, message: 'Please input the minimum quantity!' }]}
            >
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
          </>
        );
      case 'has_relationship':
        return (
          <Form.Item
            name={['trigger', 'relationship']}
            label="Relationship Type"
            rules={[{ required: true, message: 'Please select the relationship type!' }]}
          >
            <Select placeholder="Select relationship type">
              <Select.Option value="spouse">Spouse</Select.Option>
              <Select.Option value="child">Child</Select.Option>
              <Select.Option value="parent">Parent</Select.Option>
              <Select.Option value="sibling">Sibling</Select.Option>
              <Select.Option value="friend">Friend</Select.Option>
            </Select>
          </Form.Item>
        );
      case 'satisfaction_above':
      case 'satisfaction_below':
        return (
          <>
            <Form.Item
              name={['trigger', 'cravingType']}
              label="Craving Type"
              rules={[{ required: true, message: 'Please input the craving type!' }]}
            >
              <Input placeholder="e.g., biological, safety, social_connection" />
            </Form.Item>
            <Form.Item
              name={['trigger', 'threshold']}
              label="Threshold"
              rules={[{ required: true, message: 'Please input the threshold!' }]}
            >
              <InputNumber min={0} max={100} style={{ width: '100%' }} />
            </Form.Item>
          </>
        );
      case 'class_change':
        return (
          <Form.Item
            name={['trigger', 'newClass']}
            label="New Class"
            rules={[{ required: true, message: 'Please select the new class!' }]}
          >
            <Select placeholder="Select new class">
              <Select.Option value="lower">Lower</Select.Option>
              <Select.Option value="middle">Middle</Select.Option>
              <Select.Option value="upper">Upper</Select.Option>
              <Select.Option value="elite">Elite</Select.Option>
            </Select>
          </Form.Item>
        );
      default:
        return null;
    }
  };

  const renderTriggerInfo = (rule: EnablementRule) => {
    const trigger = rule.trigger;
    switch (trigger.type) {
      case 'owns_commodity_tag':
        return `Owns ${trigger.minQuantity}+ commodities with tag "${trigger.tag}"`;
      case 'has_relationship':
        return `Has ${trigger.relationship} relationship`;
      case 'satisfaction_above':
        return `${trigger.cravingType} satisfaction > ${trigger.threshold}%`;
      case 'satisfaction_below':
        return `${trigger.cravingType} satisfaction < ${trigger.threshold}%`;
      case 'class_change':
        return `Promoted to ${trigger.newClass} class`;
      default:
        return 'Unknown trigger';
    }
  };

  // Table columns
  const columns = [
    {
      title: 'ID',
      dataIndex: 'id',
      key: 'id',
      width: 180,
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
      title: 'Trigger Type',
      key: 'triggerType',
      width: 180,
      render: (_: any, record: EnablementRule) => (
        <Tag color={getTriggerColor(record.trigger.type)}>
          {record.trigger.type.replace(/_/g, ' ')}
        </Tag>
      ),
    },
    {
      title: 'Permanent',
      key: 'permanent',
      width: 100,
      render: (_: any, record: EnablementRule) => (
        record.effect.permanent ? <Tag color="gold">Yes</Tag> : <Tag>No</Tag>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      fixed: 'right' as const,
      render: (_: any, record: EnablementRule) => (
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
          <Popconfirm
            title="Delete this rule?"
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

  if (!data || !dimensions) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <span>Enablement Rules</span>
            <Tag color="blue">Version {data.version}</Tag>
          </Space>
        }
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
          >
            Add Enablement Rule
          </Button>
        }
      >
        <Table
          columns={columns}
          dataSource={data.rules}
          rowKey="id"
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{ pageSize: 15 }}
        />
      </Card>

      {/* Edit/Add Modal */}
      <Modal
        title={editing ? 'Edit Enablement Rule' : 'Add Enablement Rule'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={1200}
      >
        <Form form={form} layout="vertical">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="id"
                label="ID"
                rules={[{ required: true, message: 'Please input the ID!' }]}
              >
                <Input placeholder="e.g., owns_house" disabled={!!editing} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="name"
                label="Name"
                rules={[{ required: true, message: 'Please input the name!' }]}
              >
                <Input placeholder="e.g., Homeownership Effect" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="description"
            label="Description"
            rules={[{ required: true, message: 'Please input the description!' }]}
          >
            <TextArea rows={2} placeholder="Describe this rule..." />
          </Form.Item>

          <Card title="Trigger" size="small" style={{ marginBottom: 16 }}>
            <Form.Item
              name={['trigger', 'type']}
              label="Trigger Type"
              rules={[{ required: true, message: 'Please select the trigger type!' }]}
            >
              <Select
                placeholder="Select trigger type"
                onChange={(value) => setTriggerType(value)}
              >
                <Select.Option value="owns_commodity_tag">Owns Commodity Tag</Select.Option>
                <Select.Option value="has_relationship">Has Relationship</Select.Option>
                <Select.Option value="satisfaction_above">Satisfaction Above</Select.Option>
                <Select.Option value="satisfaction_below">Satisfaction Below</Select.Option>
                <Select.Option value="class_change">Class Change</Select.Option>
              </Select>
            </Form.Item>

            {renderTriggerFields()}
          </Card>

          <Card title="Effect" size="small" style={{ marginBottom: 16 }}>
            <Form.Item
              name={['effect', 'permanent']}
              label="Permanent"
              valuePropName="checked"
              help="If checked, this modifier persists forever (e.g., for class changes)"
            >
              <input type="checkbox" />
            </Form.Item>

            <Form.Item
              name={['effect', 'cravingModifier', 'fine']}
              label="Craving Modifier (Fine - 50D)"
              help="Modifiers add to base craving values. Positive values increase cravings, negative values decrease them."
            >
              <VectorEditor
                dimensions={dimensions.fineDimensions}
                values={form.getFieldValue(['effect', 'cravingModifier', 'fine']) || new Array(50).fill(0)}
                onChange={(values) => {
                  const currentValues = form.getFieldsValue();
                  form.setFieldsValue({
                    effect: {
                      ...currentValues.effect,
                      cravingModifier: {
                        ...currentValues.effect?.cravingModifier,
                        fine: values,
                      }
                    }
                  });
                }}
                min={-5}
                max={5}
                step={0.5}
                title="Fine Craving Modifier (50D)"
                showCoarseView={true}
                groupByParent={true}
              />
            </Form.Item>
          </Card>
        </Form>
      </Modal>

      {/* View Modal */}
      <Modal
        title={
          <Space>
            <span>View Rule: {viewing?.name}</span>
            {viewing && <Tag color={getTriggerColor(viewing.trigger.type)}>{viewing.trigger.type.replace(/_/g, ' ')}</Tag>}
            {viewing?.effect.permanent && <Tag color="gold">Permanent</Tag>}
          </Space>
        }
        open={isViewModalVisible}
        onCancel={() => setIsViewModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setIsViewModalVisible(false)}>
            Close
          </Button>
        ]}
        width={1400}
      >
        {viewing && (
          <Space direction="vertical" style={{ width: '100%' }} size="large">
            <Card size="small">
              <Row gutter={[16, 16]}>
                <Col span={12}>
                  <strong>ID:</strong> {viewing.id}
                </Col>
                <Col span={12}>
                  <strong>Name:</strong> {viewing.name}
                </Col>
                <Col span={24}>
                  <strong>Description:</strong> {viewing.description}
                </Col>
                <Col span={24}>
                  <strong>Trigger:</strong> {renderTriggerInfo(viewing)}
                </Col>
                <Col span={24}>
                  <strong>Permanent:</strong> {viewing.effect.permanent ? 'Yes' : 'No'}
                </Col>
              </Row>
            </Card>

            <VectorVisualization
              dimensions={dimensions.coarseDimensions}
              values={viewing.effect.cravingModifier.coarse}
              title="Coarse Craving Modifier (9D)"
              maxValue={5}
            />

            <VectorHeatmap
              dimensions={dimensions.fineDimensions}
              values={viewing.effect.cravingModifier.fine}
              title="Fine Craving Modifier (50D)"
              maxValue={5}
              colorScheme="blue"
            />
          </Space>
        )}
      </Modal>
    </div>
  );
};

export default EnablementRulesManager;
