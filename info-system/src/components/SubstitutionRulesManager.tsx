import { useState, useEffect } from 'react';
import { Card, Table, Button, Space, InputNumber, message, Tag, Modal, Form, Select, Collapse, Switch, Popconfirm } from 'antd';
import { SwapOutlined, PlusOutlined, EditOutlined, DeleteOutlined, SaveOutlined } from '@ant-design/icons';
import type { SubstitutionRulesData, SubstituteRule, CommoditiesData } from '../types';
import { loadSubstitutionRules, saveSubstitutionRules, loadCommodities } from '../api';

const { Panel } = Collapse;

const SubstitutionRulesManager: React.FC = () => {
  const [data, setData] = useState<SubstitutionRulesData | null>(null);
  const [commodities, setCommodities] = useState<CommoditiesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [editingCategory, setEditingCategory] = useState<string | null>(null);
  const [editingCommodity, setEditingCommodity] = useState<string | null>(null);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [substitutionData, commoditiesData] = await Promise.all([
        loadSubstitutionRules(),
        loadCommodities()
      ]);
      setData(substitutionData);
      setCommodities(commoditiesData);
    } catch (error) {
      console.error('Failed to load data:', error);
      message.error('Failed to load substitution rules');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!data) return;

    setSaving(true);
    try {
      await saveSubstitutionRules(data);
      message.success('Substitution rules saved successfully');
    } catch (error) {
      console.error('Failed to save data:', error);
      message.error('Failed to save substitution rules');
    } finally {
      setSaving(false);
    }
  };

  const handleAddSubstitute = (category: string, commodityId: string) => {
    form.resetFields();
    setEditingCategory(category);
    setEditingCommodity(commodityId);
    setEditModalVisible(true);
  };

  const handleEditSubstitute = (category: string, commodityId: string, substituteIndex: number) => {
    if (!data) return;

    const substitute = data.substitutionHierarchies[category][commodityId].substitutes[substituteIndex];
    form.setFieldsValue({
      substitute: substitute.commodity,
      efficiency: substitute.efficiency,
      distance: substitute.distance
    });
    setEditingCategory(category);
    setEditingCommodity(commodityId);
    form.setFieldValue('editingIndex', substituteIndex);
    setEditModalVisible(true);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data || !editingCategory || !editingCommodity) return;

      const newData = { ...data };
      const substitutes = [...newData.substitutionHierarchies[editingCategory][editingCommodity].substitutes];

      const newSubstitute: SubstituteRule = {
        commodity: values.substitute,
        efficiency: values.efficiency,
        distance: values.distance
      };

      const editingIndex = form.getFieldValue('editingIndex');
      if (editingIndex !== undefined) {
        substitutes[editingIndex] = newSubstitute;
      } else {
        substitutes.push(newSubstitute);
      }

      newData.substitutionHierarchies[editingCategory][editingCommodity].substitutes = substitutes;
      setData(newData);
      setEditModalVisible(false);
      message.success('Substitute updated');
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const handleDeleteSubstitute = (category: string, commodityId: string, index: number) => {
    if (!data) return;

    const newData = { ...data };
    newData.substitutionHierarchies[category][commodityId].substitutes.splice(index, 1);
    setData(newData);
    message.success('Substitute removed');
  };

  const handleDesperationEnabledChange = (enabled: boolean) => {
    if (!data) return;
    setData({
      ...data,
      desperationRules: {
        enabled,
        desperationThreshold: data.desperationRules?.desperationThreshold || 20,
        desperationSubstitutes: data.desperationRules?.desperationSubstitutes || {}
      }
    });
  };

  const handleDesperationThresholdChange = (value: number | null) => {
    if (!data || value === null) return;
    setData({
      ...data,
      desperationRules: {
        enabled: data.desperationRules?.enabled || false,
        desperationThreshold: value,
        desperationSubstitutes: data.desperationRules?.desperationSubstitutes || {}
      }
    });
  };

  const getCommodityName = (commodityId: string): string => {
    return commodities?.commodities.find(c => c.id === commodityId)?.name || commodityId;
  };

  const renderSubstituteTable = (category: string, commodityId: string, substitutes: SubstituteRule[]) => {
    const columns = [
      {
        title: 'Substitute',
        dataIndex: 'commodity',
        key: 'commodity',
        render: (commodity: string) => getCommodityName(commodity),
      },
      {
        title: 'Efficiency',
        dataIndex: 'efficiency',
        key: 'efficiency',
        width: 120,
        render: (efficiency: number) => <Tag color={efficiency >= 1 ? 'green' : 'orange'}>{(efficiency * 100).toFixed(0)}%</Tag>,
      },
      {
        title: 'Distance',
        dataIndex: 'distance',
        key: 'distance',
        width: 120,
        render: (distance: number) => {
          const color = distance <= 0.15 ? 'green' : distance <= 0.35 ? 'blue' : distance <= 0.55 ? 'orange' : 'red';
          return <Tag color={color}>{distance.toFixed(2)}</Tag>;
        },
      },
      {
        title: 'Actions',
        key: 'actions',
        width: 150,
        render: (_: any, __: any, index: number) => (
          <Space>
            <Button
              size="small"
              icon={<EditOutlined />}
              onClick={() => handleEditSubstitute(category, commodityId, index)}
            />
            <Popconfirm
              title="Remove this substitute?"
              onConfirm={() => handleDeleteSubstitute(category, commodityId, index)}
              okText="Yes"
              cancelText="No"
            >
              <Button size="small" danger icon={<DeleteOutlined />} />
            </Popconfirm>
          </Space>
        ),
      },
    ];

    return (
      <div>
        <Table
          columns={columns}
          dataSource={substitutes.map((s, i) => ({ ...s, key: i }))}
          pagination={false}
          size="small"
        />
        <Button
          type="dashed"
          icon={<PlusOutlined />}
          onClick={() => handleAddSubstitute(category, commodityId)}
          style={{ marginTop: 8 }}
        >
          Add Substitute
        </Button>
      </div>
    );
  };

  const renderCategoryPanel = (category: string) => {
    if (!data) return null;

    const commoditiesInCategory = data.substitutionHierarchies[category];

    return (
      <Panel header={<strong>{category.charAt(0).toUpperCase() + category.slice(1)}</strong>} key={category}>
        <Collapse>
          {Object.entries(commoditiesInCategory).map(([commodityId, commodityData]) => (
            <Panel
              header={
                <Space>
                  <span>{getCommodityName(commodityId)}</span>
                  <Tag>{commodityData.substitutes.length} substitutes</Tag>
                </Space>
              }
              key={commodityId}
            >
              {renderSubstituteTable(category, commodityId, commodityData.substitutes)}
            </Panel>
          ))}
        </Collapse>
      </Panel>
    );
  };

  if (loading || !data || !commodities) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <SwapOutlined />
            <span>Substitution Rules Manager</span>
          </Space>
        }
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            onClick={handleSave}
            loading={saving}
          >
            Save All Changes
          </Button>
        }
      >
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Card size="small" title="Desperation Rules">
            <Space direction="vertical" style={{ width: '100%' }}>
              <div>
                <strong>Enabled:</strong>
                <Switch
                  checked={data.desperationRules?.enabled || false}
                  onChange={handleDesperationEnabledChange}
                  style={{ marginLeft: 8 }}
                />
              </div>
              <div>
                <strong>Desperation Threshold:</strong>
                <InputNumber
                  min={0}
                  max={100}
                  value={data.desperationRules?.desperationThreshold || 20}
                  onChange={handleDesperationThresholdChange}
                  style={{ marginLeft: 8, width: 120 }}
                />
                <span style={{ marginLeft: 8, color: '#888' }}>
                  (Satisfaction level below which desperation substitutes are enabled)
                </span>
              </div>
            </Space>
          </Card>

          <Card size="small" title="Substitution Hierarchies">
            <Collapse>
              {Object.keys(data.substitutionHierarchies).map((category) =>
                renderCategoryPanel(category)
              )}
            </Collapse>
          </Card>
        </Space>
      </Card>

      <Modal
        title="Edit Substitute"
        open={editModalVisible}
        onOk={handleModalOk}
        onCancel={() => setEditModalVisible(false)}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="editingIndex" hidden>
            <InputNumber />
          </Form.Item>
          <Form.Item
            name="substitute"
            label="Substitute Commodity"
            rules={[{ required: true, message: 'Please select a substitute commodity' }]}
          >
            <Select
              showSearch
              placeholder="Select commodity"
              filterOption={(input, option) =>
                (option?.children as string).toLowerCase().includes(input.toLowerCase())
              }
            >
              {commodities?.commodities.map(c => (
                <Select.Option key={c.id} value={c.id}>
                  {c.name} ({c.category})
                </Select.Option>
              ))}
            </Select>
          </Form.Item>
          <Form.Item
            name="efficiency"
            label="Efficiency"
            rules={[{ required: true, message: 'Please enter efficiency' }]}
            extra="How well this substitute fulfills the need (0.0 to 2.0, where 1.0 = same, >1.0 = better)"
          >
            <InputNumber min={0} max={2} step={0.05} style={{ width: '100%' }} />
          </Form.Item>
          <Form.Item
            name="distance"
            label="Distance"
            rules={[{ required: true, message: 'Please enter distance' }]}
            extra="How 'close' this substitute is (0.0 = very close, 1.0 = very distant). Closer substitutes receive better variety boost."
          >
            <InputNumber min={0} max={1} step={0.01} style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
};

export default SubstitutionRulesManager;
