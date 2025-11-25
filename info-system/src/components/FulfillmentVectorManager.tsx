import { useState, useEffect } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Space, message, Popconfirm, Tag, Row, Col } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined, ThunderboltOutlined } from '@ant-design/icons';
import type { FulfillmentVectorsData, CommodityFulfillment, DimensionDefinitions, CommoditiesData } from '../types';
import { loadFulfillmentVectors, saveFulfillmentVectors, loadDimensionDefinitions, loadCommodities } from '../api';
import VectorEditor from './VectorEditor';
import VectorVisualization from './VectorVisualization';
import VectorHeatmap from './VectorHeatmap';
import QuickFillModal from './QuickFillModal';
import { QUALITY_MULTIPLIERS, type VectorTemplate } from '../constants';

const { TextArea } = Input;

const FulfillmentVectorManager: React.FC = () => {
  const [data, setData] = useState<FulfillmentVectorsData | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDefinitions | null>(null);
  const [commodities, setCommodities] = useState<CommoditiesData | null>(null);
  const [loading, setLoading] = useState(true);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [viewing, setViewing] = useState<{ id: string; data: CommodityFulfillment } | null>(null);
  const [isModalVisible, setIsModalVisible] = useState(false);
  const [isViewModalVisible, setIsViewModalVisible] = useState(false);
  const [isQuickFillVisible, setIsQuickFillVisible] = useState(false);
  const [form] = Form.useForm();

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [fulfillmentData, dimensionsData, commoditiesData] = await Promise.all([
        loadFulfillmentVectors(),
        loadDimensionDefinitions(),
        loadCommodities()
      ]);
      setData(fulfillmentData);
      setDimensions(dimensionsData);
      setCommodities(commoditiesData);
    } catch (error) {
      message.error('Failed to load fulfillment vectors');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const saveData = async (newData: FulfillmentVectorsData) => {
    try {
      await saveFulfillmentVectors(newData);
      setData(newData);
      message.success('Fulfillment vectors saved successfully');
    } catch (error) {
      message.error('Failed to save fulfillment vectors');
      console.error(error);
    }
  };

  const handleAdd = () => {
    setEditingId(null);
    form.resetFields();
    // Set default values
    form.setFieldsValue({
      fulfillmentVector: {
        coarse: new Array(9).fill(0),
        fine: {},
      },
      tags: [],
      durability: 'single-use',
      qualityMultipliers: {
        poor: 0.6,
        basic: 1.0,
        good: 1.4,
        luxury: 2.0,
        masterwork: 3.0,
      },
    });
    setIsModalVisible(true);
  };

  const handleEdit = (commodityId: string, record: CommodityFulfillment) => {
    setEditingId(commodityId);
    form.setFieldsValue({
      id: commodityId,
      ...record,
      tags: record.tags.join(', '),
    });
    setIsModalVisible(true);
  };

  const handleView = (commodityId: string, record: CommodityFulfillment) => {
    setViewing({ id: commodityId, data: record });
    setIsViewModalVisible(true);
  };

  const handleDelete = (commodityId: string) => {
    if (!data) return;

    const newCommodities = { ...data.commodities };
    delete newCommodities[commodityId];

    const newData: FulfillmentVectorsData = {
      ...data,
      commodities: newCommodities,
    };

    saveData(newData);
  };

  const handleModalOk = async () => {
    try {
      const values = await form.validateFields();
      if (!data) return;

      const commodityId = values.id || editingId;
      if (!commodityId) {
        message.error('Commodity ID is required');
        return;
      }

      // Parse tags
      const tags = typeof values.tags === 'string'
        ? values.tags.split(',').map((t: string) => t.trim()).filter((t: string) => t)
        : values.tags;

      const newCommodityData: CommodityFulfillment = {
        id: commodityId,
        fulfillmentVector: values.fulfillmentVector,
        tags,
        durability: values.durability,
        qualityMultipliers: values.qualityMultipliers,
        reusableValue: values.reusableValue,
        notes: values.notes,
      };

      const newData: FulfillmentVectorsData = {
        ...data,
        commodities: {
          ...data.commodities,
          [commodityId]: newCommodityData,
        },
      };

      await saveData(newData);
      setIsModalVisible(false);
      form.resetFields();
    } catch (error) {
      console.error('Validation failed:', error);
    }
  };

  // Handle Quick Fill batch application
  const handleQuickFillApply = (fills: Array<{ commodityId: string; template: VectorTemplate; qualityPreset: string }>) => {
    if (!data) return;

    const newCommodities = { ...data.commodities };

    fills.forEach(({ commodityId, template, qualityPreset }) => {
      newCommodities[commodityId] = {
        id: commodityId,
        fulfillmentVector: {
          coarse: new Array(9).fill(0), // Will be calculated from fine
          fine: template.fine,
        },
        tags: template.tags,
        durability: template.durability,
        qualityMultipliers: QUALITY_MULTIPLIERS[qualityPreset as keyof typeof QUALITY_MULTIPLIERS] || QUALITY_MULTIPLIERS.basic_food,
        notes: template.notes,
      };
    });

    const newData: FulfillmentVectorsData = {
      ...data,
      commodities: newCommodities,
    };

    saveData(newData);
  };

  // Convert data to table format
  const tableData = data ? Object.entries(data.commodities).map(([id, commodity]) => ({
    key: id,
    id,
    ...commodity,
  })) : [];

  // Table columns
  const columns = [
    {
      title: 'Commodity ID',
      dataIndex: 'id',
      key: 'id',
      width: 200,
      sorter: (a: any, b: any) => a.id.localeCompare(b.id),
    },
    {
      title: 'Tags',
      dataIndex: 'tags',
      key: 'tags',
      render: (tags: string[]) => (
        <>
          {tags.slice(0, 3).map(tag => (
            <Tag key={tag} color="green">{tag}</Tag>
          ))}
          {tags.length > 3 && <Tag>+{tags.length - 3}</Tag>}
        </>
      ),
    },
    {
      title: 'Durability',
      dataIndex: 'durability',
      key: 'durability',
      width: 150,
      render: (durability: string) => {
        const color = durability === 'single-use' ? 'orange' : durability === 'consumable' ? 'blue' : 'green';
        return <Tag color={color}>{durability}</Tag>;
      },
    },
    {
      title: 'Active Dimensions',
      key: 'activeDimensions',
      width: 150,
      align: 'center' as const,
      render: (_: any, record: any) => {
        const fineCount = Object.keys(record.fulfillmentVector.fine || {}).length;
        const coarseCount = record.fulfillmentVector.coarse.filter((v: number) => v > 0).length;
        return (
          <Space>
            <Tag color="blue">Fine: {fineCount}</Tag>
            <Tag color="purple">Coarse: {coarseCount}</Tag>
          </Space>
        );
      },
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 150,
      fixed: 'right' as const,
      render: (_: any, record: any) => (
        <Space>
          <Button
            type="link"
            icon={<EyeOutlined />}
            onClick={() => handleView(record.id, record)}
          />
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEdit(record.id, record)}
          />
          <Popconfirm
            title="Delete this fulfillment vector?"
            onConfirm={() => handleDelete(record.id)}
            okText="Yes"
            cancelText="No"
          >
            <Button type="link" danger icon={<DeleteOutlined />} />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // Convert fine dimension object to array for VectorEditor
  const fineObjectToArray = (fine: Record<string, number>): number[] => {
    if (!dimensions) return new Array(50).fill(0);
    return dimensions.fineDimensions.map(dim => fine[dim.id] || 0);
  };

  // Convert fine dimension array to object
  const fineArrayToObject = (fineArray: number[]): Record<string, number> => {
    if (!dimensions) return {};
    const result: Record<string, number> = {};
    dimensions.fineDimensions.forEach((dim, index) => {
      if (fineArray[index] && fineArray[index] > 0) {
        result[dim.id] = fineArray[index];
      }
    });
    return result;
  };

  if (!data || !dimensions || !commodities) {
    return <div>Loading...</div>;
  }

  return (
    <div>
      <Card
        title={
          <Space>
            <span>Fulfillment Vectors</span>
            <Tag color="blue">Version {data.version}</Tag>
            <Tag color="purple">{Object.keys(data.commodities).length} commodities</Tag>
          </Space>
        }
        extra={
          <Space>
            <Button
              icon={<ThunderboltOutlined />}
              onClick={() => setIsQuickFillVisible(true)}
            >
              Quick Fill ({commodities && data ? commodities.commodities.length - Object.keys(data.commodities).length : 0} missing)
            </Button>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleAdd}
            >
              Add Fulfillment Vector
            </Button>
          </Space>
        }
      >
        {data.note && (
          <Card size="small" style={{ marginBottom: 16, background: '#f0f2f5' }}>
            <strong>Note:</strong> {data.note}
          </Card>
        )}
        <Table
          columns={columns}
          dataSource={tableData}
          loading={loading}
          scroll={{ x: 1000 }}
          pagination={{ pageSize: 15 }}
        />
      </Card>

      {/* Edit/Add Modal */}
      <Modal
        title={editingId ? `Edit Fulfillment Vector: ${editingId}` : 'Add Fulfillment Vector'}
        open={isModalVisible}
        onOk={handleModalOk}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={1200}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            name="id"
            label="Commodity ID"
            rules={[{ required: true, message: 'Please select or input the commodity ID!' }]}
          >
            <Select
              showSearch
              placeholder="Select a commodity or type a new ID"
              disabled={!!editingId}
              mode={editingId ? undefined : 'tags'}
            >
              {commodities.commodities.map(c => (
                <Select.Option key={c.id} value={c.id}>
                  {c.name} ({c.id})
                </Select.Option>
              ))}
            </Select>
          </Form.Item>

          <Form.Item
            name="tags"
            label="Tags (comma-separated)"
            rules={[{ required: true, message: 'Please input tags!' }]}
          >
            <Input placeholder="e.g., grain, nutrition, processed_food" />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="durability"
                label="Durability"
                rules={[{ required: true, message: 'Please select durability!' }]}
              >
                <Select>
                  <Select.Option value="single-use">Single Use</Select.Option>
                  <Select.Option value="consumable">Consumable</Select.Option>
                  <Select.Option value="durable">Durable</Select.Option>
                  <Select.Option value="permanent">Permanent</Select.Option>
                </Select>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="reusableValue"
                label="Reusable Value (if durable/permanent)"
              >
                <InputNumber min={0} max={100} style={{ width: '100%' }} />
              </Form.Item>
            </Col>
          </Row>

          <Card size="small" title="Quality Multipliers" style={{ marginBottom: 16 }}>
            <Row gutter={[16, 8]}>
              <Col span={4}>
                <Form.Item name={['qualityMultipliers', 'poor']} label="Poor">
                  <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
              <Col span={4}>
                <Form.Item name={['qualityMultipliers', 'basic']} label="Basic">
                  <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
              <Col span={5}>
                <Form.Item name={['qualityMultipliers', 'good']} label="Good">
                  <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
              <Col span={5}>
                <Form.Item name={['qualityMultipliers', 'luxury']} label="Luxury">
                  <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
              <Col span={6}>
                <Form.Item name={['qualityMultipliers', 'masterwork']} label="Masterwork">
                  <InputNumber min={0} max={5} step={0.1} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
            </Row>
          </Card>

          <Form.Item
            name="notes"
            label="Notes"
          >
            <TextArea rows={2} placeholder="Additional notes about this fulfillment vector..." />
          </Form.Item>

          <Form.Item
            shouldUpdate={(prevValues, currentValues) =>
              prevValues.fulfillmentVector?.fine !== currentValues.fulfillmentVector?.fine
            }
          >
            {() => (
              <VectorEditor
                dimensions={dimensions.fineDimensions}
                values={fineObjectToArray(form.getFieldValue(['fulfillmentVector', 'fine']) || {})}
                onChange={(values) => {
                  form.setFieldsValue({
                    fulfillmentVector: {
                      coarse: new Array(9).fill(0),
                      fine: fineArrayToObject(values),
                    }
                  });
                }}
                min={0}
                max={20}
                step={0.5}
                title="Fulfillment Vector (Fine - 50D)"
                showCoarseView={true}
                groupByParent={true}
              />
            )}
          </Form.Item>
        </Form>
      </Modal>

      {/* View Modal */}
      <Modal
        title={`View Fulfillment Vector: ${viewing?.id}`}
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
                  <strong>Commodity ID:</strong> {viewing.id}
                </Col>
                <Col span={12}>
                  <strong>Durability:</strong>{' '}
                  <Tag color={
                    viewing.data.durability === 'single-use' ? 'orange' :
                    viewing.data.durability === 'consumable' ? 'blue' : 'green'
                  }>
                    {viewing.data.durability}
                  </Tag>
                </Col>
                <Col span={24}>
                  <strong>Tags:</strong>{' '}
                  {viewing.data.tags.map(tag => (
                    <Tag key={tag} color="green">{tag}</Tag>
                  ))}
                </Col>
                {viewing.data.reusableValue && (
                  <Col span={12}>
                    <strong>Reusable Value:</strong> {viewing.data.reusableValue}
                  </Col>
                )}
                <Col span={24}>
                  <strong>Quality Multipliers:</strong>
                  <div style={{ marginTop: 8 }}>
                    {Object.entries(viewing.data.qualityMultipliers).map(([quality, multiplier]) => (
                      <Tag key={quality} color="blue">
                        {quality}: {multiplier}x
                      </Tag>
                    ))}
                  </div>
                </Col>
                {viewing.data.notes && (
                  <Col span={24}>
                    <strong>Notes:</strong> {viewing.data.notes}
                  </Col>
                )}
              </Row>
            </Card>

            <VectorVisualization
              dimensions={dimensions.coarseDimensions}
              values={viewing.data.fulfillmentVector.coarse}
              title="Coarse Fulfillment Profile (9D)"
              maxValue={20}
            />

            <VectorHeatmap
              dimensions={dimensions.fineDimensions}
              values={fineObjectToArray(viewing.data.fulfillmentVector.fine)}
              title="Fine Fulfillment Vector (50D)"
              maxValue={20}
              colorScheme="green"
            />
          </Space>
        )}
      </Modal>

      {/* Quick Fill Modal */}
      {commodities && data && (
        <QuickFillModal
          visible={isQuickFillVisible}
          onClose={() => setIsQuickFillVisible(false)}
          commodities={commodities.commodities}
          existingFulfillmentIds={Object.keys(data.commodities)}
          onApply={handleQuickFillApply}
        />
      )}
    </div>
  );
};

export default FulfillmentVectorManager;
