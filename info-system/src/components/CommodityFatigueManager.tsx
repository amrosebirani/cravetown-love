import { useState, useEffect } from 'react';
import { Card, Table, Button, Space, InputNumber, message, Tag, Modal, Form, Input, Popconfirm } from 'antd';
import { ThunderboltOutlined, PlusOutlined, EditOutlined, DeleteOutlined, SaveOutlined } from '@ant-design/icons';
import type { CommodityFatigueRatesData, CommodityFatigueRate, CommoditiesData } from '../types';
import { loadCommodityFatigueRates, saveCommodityFatigueRates, loadCommodities } from '../api';

const CommodityFatigueManager: React.FC = () => {
  const [data, setData] = useState<CommodityFatigueRatesData | null>(null);
  const [commodities, setCommodities] = useState<CommoditiesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [editModalVisible, setEditModalVisible] = useState(false);
  const [modifierModalVisible, setModifierModalVisible] = useState(false);
  const [editingCommodity, setEditingCommodity] = useState<string | null>(null);
  const [form] = Form.useForm();
  const [modifierForm] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [fatigueData, commoditiesData] = await Promise.all([
        loadCommodityFatigueRates(),
        loadCommodities()
      ]);
      setData(fatigueData);
      setCommodities(commoditiesData);
    } catch (error) {
      console.error('Failed to load data:', error);
      message.error('Failed to load commodity fatigue rates');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!data) return;

    setSaving(true);
    try {
      await saveCommodityFatigueRates(data);
      message.success('Commodity fatigue rates saved successfully');
    } catch (error) {
      console.error('Failed to save data:', error);
      message.error('Failed to save commodity fatigue rates');
    } finally {
      setSaving(false);
    }
  };

  const handleBaseFatigueRateChange = (commodityId: string, value: number | null) => {
    if (!data || value === null) return;

    const newData = { ...data };
    if (!newData.commodities[commodityId]) {
      newData.commodities[commodityId] = {
        baseFatigueRate: value,
        fatigueModifiers: {}
      };
    } else {
      newData.commodities[commodityId] = {
        ...newData.commodities[commodityId],
        baseFatigueRate: value
      };
    }
    setData(newData);
  };

  const handleAddCommodity = () => {
    form.resetFields();
    setEditingCommodity(null);
    setEditModalVisible(true);
  };

  const handleEditCommodity = (commodityId: string) => {
    const commodityData = data?.commodities[commodityId];
    form.setFieldsValue({
      commodityId,
      baseFatigueRate: commodityData?.baseFatigueRate || data?.defaultFatigueRate || 0.12
    });
    setEditingCommodity(commodityId);
    setEditModalVisible(true);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      const newData = { ...data };
      newData.commodities[values.commodityId] = {
        baseFatigueRate: values.baseFatigueRate,
        fatigueModifiers: newData.commodities[values.commodityId]?.fatigueModifiers || {}
      };
      setData(newData);
      setEditModalVisible(false);
      message.success('Commodity fatigue rate updated');
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const handleDeleteCommodity = (commodityId: string) => {
    if (!data) return;

    const newData = { ...data };
    delete newData.commodities[commodityId];
    setData(newData);
    message.success('Commodity fatigue rate removed');
  };

  const handleEditModifiers = (commodityId: string) => {
    const commodityData = data?.commodities[commodityId];
    setEditingCommodity(commodityId);
    modifierForm.setFieldsValue({
      modifiers: Object.entries(commodityData?.fatigueModifiers || {}).map(([trait, value]) => ({
        trait,
        value
      }))
    });
    setModifierModalVisible(true);
  };

  const handleModifierModalOk = async () => {
    try {
      const values = await modifierForm.validateFields();
      if (!data || !editingCommodity) return;

      const newData = { ...data };
      const modifiers: Record<string, number> = {};
      values.modifiers?.forEach((m: { trait: string; value: number }) => {
        modifiers[m.trait] = m.value;
      });

      newData.commodities[editingCommodity] = {
        ...newData.commodities[editingCommodity],
        fatigueModifiers: modifiers
      };
      setData(newData);
      setModifierModalVisible(false);
      message.success('Trait modifiers updated');
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  const getCommodityName = (commodityId: string): string => {
    return commodities?.commodities.find(c => c.id === commodityId)?.name || commodityId;
  };

  const getCommodityCategory = (commodityId: string): string => {
    return commodities?.commodities.find(c => c.id === commodityId)?.category || 'unknown';
  };

  const columns = [
    {
      title: 'Commodity',
      dataIndex: 'commodityId',
      key: 'commodity',
      width: 200,
      render: (commodityId: string) => getCommodityName(commodityId),
      sorter: (a: any, b: any) => getCommodityName(a.commodityId).localeCompare(getCommodityName(b.commodityId)),
    },
    {
      title: 'Category',
      dataIndex: 'commodityId',
      key: 'category',
      width: 150,
      render: (commodityId: string) => <Tag>{getCommodityCategory(commodityId)}</Tag>,
    },
    {
      title: 'Base Fatigue Rate',
      dataIndex: 'baseFatigueRate',
      key: 'baseFatigueRate',
      width: 180,
      render: (rate: number, record: any) => (
        <InputNumber
          min={0}
          max={1}
          step={0.01}
          value={rate}
          onChange={(value) => handleBaseFatigueRateChange(record.commodityId, value)}
          style={{ width: '100%' }}
        />
      ),
    },
    {
      title: 'Trait Modifiers',
      key: 'modifiers',
      width: 250,
      render: (_: any, record: any) => {
        const modifiers = data?.commodities[record.commodityId]?.fatigueModifiers || {};
        const count = Object.keys(modifiers).length;
        return (
          <Space>
            <Tag color="blue">{count} traits</Tag>
            <Button
              size="small"
              icon={<EditOutlined />}
              onClick={() => handleEditModifiers(record.commodityId)}
            >
              Edit Modifiers
            </Button>
          </Space>
        );
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      render: (_: any, record: any) => (
        <Space>
          <Button
            size="small"
            icon={<EditOutlined />}
            onClick={() => handleEditCommodity(record.commodityId)}
          />
          <Popconfirm
            title="Remove this commodity?"
            onConfirm={() => handleDeleteCommodity(record.commodityId)}
            okText="Yes"
            cancelText="No"
          >
            <Button size="small" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  const tableData = data ? Object.entries(data.commodities).map(([commodityId, fatigueData]) => ({
    key: commodityId,
    commodityId,
    ...fatigueData
  })) : [];

  if (loading || !data || !commodities) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <ThunderboltOutlined />
            <span>Commodity Fatigue Rates</span>
          </Space>
        }
        extra={
          <Space>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleAddCommodity}
            >
              Add Commodity
            </Button>
            <Button
              type="primary"
              icon={<SaveOutlined />}
              onClick={handleSave}
              loading={saving}
            >
              Save All Changes
            </Button>
          </Space>
        }
      >
        <Space direction="vertical" style={{ width: '100%', marginBottom: 16 }}>
          <Card size="small" title="Global Settings">
            <Space direction="vertical" style={{ width: '100%' }}>
              <div>
                <strong>Default Fatigue Rate:</strong>
                <InputNumber
                  min={0}
                  max={1}
                  step={0.01}
                  value={data.defaultFatigueRate}
                  onChange={(value) => value !== null && setData({ ...data, defaultFatigueRate: value })}
                  style={{ marginLeft: 8, width: 120 }}
                />
              </div>
              <div>
                <strong>Default Recovery Rate:</strong>
                <InputNumber
                  min={0}
                  max={1}
                  step={0.01}
                  value={data.defaultRecoveryRate}
                  onChange={(value) => value !== null && setData({ ...data, defaultRecoveryRate: value })}
                  style={{ marginLeft: 8, width: 120 }}
                />
              </div>
            </Space>
          </Card>
        </Space>

        <Table
          columns={columns}
          dataSource={tableData}
          loading={loading}
          pagination={{ pageSize: 20 }}
          scroll={{ x: 1000 }}
        />
      </Card>

      <Modal
        title={editingCommodity ? 'Edit Commodity Fatigue Rate' : 'Add Commodity Fatigue Rate'}
        open={editModalVisible}
        onOk={handleModalOk}
        onCancel={() => setEditModalVisible(false)}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="commodityId"
            label="Commodity ID"
            rules={[{ required: true, message: 'Please enter commodity ID' }]}
          >
            <Input disabled={!!editingCommodity} placeholder="e.g., wheat, bread, gold" />
          </Form.Item>
          <Form.Item
            name="baseFatigueRate"
            label="Base Fatigue Rate"
            rules={[{ required: true, message: 'Please enter base fatigue rate' }]}
          >
            <InputNumber min={0} max={1} step={0.01} style={{ width: '100%' }} />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title="Edit Trait Modifiers"
        open={modifierModalVisible}
        onOk={handleModifierModalOk}
        onCancel={() => setModifierModalVisible(false)}
        width={600}
      >
        <Form form={modifierForm} layout="vertical">
          <Form.List name="modifiers">
            {(fields, { add, remove }) => (
              <>
                {fields.map((field) => (
                  <Space key={field.key} style={{ display: 'flex', marginBottom: 8 }} align="baseline">
                    <Form.Item
                      {...field}
                      name={[field.name, 'trait']}
                      rules={[{ required: true, message: 'Trait required' }]}
                    >
                      <Input placeholder="Trait ID (e.g., frugal, hedonist)" style={{ width: 200 }} />
                    </Form.Item>
                    <Form.Item
                      {...field}
                      name={[field.name, 'value']}
                      rules={[{ required: true, message: 'Value required' }]}
                    >
                      <InputNumber placeholder="Multiplier" min={0} max={5} step={0.1} style={{ width: 120 }} />
                    </Form.Item>
                    <Button onClick={() => remove(field.name)} icon={<DeleteOutlined />} />
                  </Space>
                ))}
                <Button type="dashed" onClick={() => add()} block icon={<PlusOutlined />}>
                  Add Trait Modifier
                </Button>
              </>
            )}
          </Form.List>
        </Form>
      </Modal>
    </div>
  );
};

export default CommodityFatigueManager;
