import { useState, useEffect, useMemo } from 'react';
import { Card, Table, Button, Modal, Form, Input, InputNumber, Select, Space, message, Popconfirm, Tag, Row, Col, Statistic, Tooltip } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, EyeOutlined, ThunderboltOutlined, LeftOutlined, RightOutlined, DatabaseOutlined, SyncOutlined } from '@ant-design/icons';
import type { FulfillmentVectorsData, CommodityFulfillment, DimensionDefinitions, CommoditiesData, PreComputedCommodityCache } from '../types';
import { loadFulfillmentVectors, saveFulfillmentVectors, loadDimensionDefinitions, loadCommodities, generateAndSaveCommodityCache, loadCommodityCache, cacheNeedsRegeneration } from '../api';
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

  // Cache state
  const [cacheInfo, setCacheInfo] = useState<PreComputedCommodityCache | null>(null);
  const [cacheStatus, setCacheStatus] = useState<{ needsRegeneration: boolean; reason?: string } | null>(null);
  const [generatingCache, setGeneratingCache] = useState(false);
  const [isCacheModalVisible, setIsCacheModalVisible] = useState(false);

  // Separate state for fulfillment vector since form.setFieldsValue doesn't work reliably
  const [currentFulfillmentVector, setCurrentFulfillmentVector] = useState<{
    coarse: number[];
    fine: Record<string, number>;
  }>({ coarse: new Array(9).fill(0), fine: {} });

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

      // Load cache info
      loadCacheInfo();
    } catch (error) {
      message.error('Failed to load fulfillment vectors');
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const loadCacheInfo = async () => {
    try {
      const [cache, status] = await Promise.all([
        loadCommodityCache(),
        cacheNeedsRegeneration()
      ]);
      setCacheInfo(cache);
      setCacheStatus(status);
    } catch (error) {
      console.error('Failed to load cache info:', error);
    }
  };

  const handleGenerateCache = async () => {
    setGeneratingCache(true);
    try {
      const result = await generateAndSaveCommodityCache();
      setCacheInfo(result.cache);
      setCacheStatus({ needsRegeneration: false });
      message.success(`Cache generated in ${result.generationTimeMs.toFixed(2)}ms`);
      setIsCacheModalVisible(true);
    } catch (error) {
      message.error('Failed to generate cache');
      console.error(error);
    } finally {
      setGeneratingCache(false);
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
      durationCycles: null,
      effectDecayRate: 0,
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
    // Initialize the fulfillment vector state
    setCurrentFulfillmentVector(record.fulfillmentVector || { coarse: new Array(9).fill(0), fine: {} });
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

  const handleModalOk = async (closeAfterSave: boolean = false) => {
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

      // Use the state-tracked fulfillment vector instead of form
      const fulfillmentVector = {
        coarse: currentFulfillmentVector.coarse,
        fine: currentFulfillmentVector.fine
      };

      const newCommodityData: CommodityFulfillment = {
        id: commodityId,
        fulfillmentVector,
        tags,
        durability: values.durability,
        qualityMultipliers: values.qualityMultipliers,
        durationCycles: values.durationCycles,
        effectDecayRate: values.effectDecayRate,
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

      // Only close if explicitly requested
      if (closeAfterSave) {
        setIsModalVisible(false);
        form.resetFields();
      }
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

  // Convert data to table format and create sorted list for navigation
  const tableData = data ? Object.entries(data.commodities).map(([commodityId, commodity]) => ({
    key: commodityId,
    ...commodity,
    id: commodityId,  // Ensure id matches the key (in case commodity.id differs)
  })) : [];

  // Sorted list of commodity IDs for navigation
  const sortedCommodityIds = useMemo(() => {
    return Object.keys(data?.commodities || {}).sort((a, b) => a.localeCompare(b));
  }, [data]);

  // Get current index and navigate to prev/next
  const getCurrentIndex = (commodityId: string) => {
    return sortedCommodityIds.indexOf(commodityId);
  };

  const navigateToCommodity = (commodityId: string, mode: 'view' | 'edit') => {
    if (!data) return;
    const record = data.commodities[commodityId];
    if (!record) return;

    if (mode === 'view') {
      setViewing({ id: commodityId, data: record });
    } else {
      setEditingId(commodityId);
      const { id: _recordId, ...restRecord } = record;
      form.setFieldsValue({
        id: commodityId,
        ...restRecord,
        tags: record.tags.join(', '),
      });
      // Initialize the fulfillment vector state
      setCurrentFulfillmentVector(record.fulfillmentVector || { coarse: new Array(9).fill(0), fine: {} });
    }
  };

  const handlePrevious = (currentId: string, mode: 'view' | 'edit') => {
    const currentIndex = getCurrentIndex(currentId);
    if (currentIndex > 0) {
      navigateToCommodity(sortedCommodityIds[currentIndex - 1], mode);
    }
  };

  const handleNext = (currentId: string, mode: 'view' | 'edit') => {
    const currentIndex = getCurrentIndex(currentId);
    if (currentIndex < sortedCommodityIds.length - 1) {
      navigateToCommodity(sortedCommodityIds[currentIndex + 1], mode);
    }
  };

  const switchToEdit = () => {
    if (!viewing || !data) return;
    const record = data.commodities[viewing.id];
    if (!record) return;

    setIsViewModalVisible(false);
    setEditingId(viewing.id);
    const { id: _recordId, ...restRecord } = record;
    form.setFieldsValue({
      id: viewing.id,
      ...restRecord,
      tags: record.tags.join(', '),
    });
    // Initialize the fulfillment vector state
    setCurrentFulfillmentVector(record.fulfillmentVector || { coarse: new Array(9).fill(0), fine: {} });
    setIsModalVisible(true);
  };

  const switchToView = async () => {
    if (!editingId || !data) return;

    // Build the current form data to show in view
    const values = form.getFieldsValue();
    const tags = typeof values.tags === 'string'
      ? values.tags.split(',').map((t: string) => t.trim()).filter((t: string) => t)
      : values.tags || [];

    const currentFormData = {
      id: editingId,
      fulfillmentVector: currentFulfillmentVector,
      tags,
      durability: values.durability,
      qualityMultipliers: values.qualityMultipliers,
      durationCycles: values.durationCycles,
      effectDecayRate: values.effectDecayRate,
      notes: values.notes,
    };

    setIsModalVisible(false);
    setViewing({ id: editingId, data: currentFormData });
    setIsViewModalVisible(true);
  };

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
        const fineCount = Object.keys(record.fulfillmentVector?.fine || {}).length;
        const coarseCount = (record.fulfillmentVector?.coarse || []).filter((v: number) => v > 0).length;
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

  // Calculate coarse values from fine values array
  const calculateCoarseFromFine = (fineArray: number[]): number[] => {
    if (!dimensions) return new Array(9).fill(0);

    // Map coarse dimension names to indices (order matters)
    const coarseOrder = dimensions.coarseDimensions.map(c => c.id);
    const coarseTotals: Record<string, number> = {};

    // Initialize all coarse dimensions to 0
    coarseOrder.forEach(id => {
      coarseTotals[id] = 0;
    });

    // Sum up fine values into their parent coarse dimensions
    dimensions.fineDimensions.forEach((dim, index) => {
      const value = fineArray[index] || 0;
      if (value > 0 && coarseTotals.hasOwnProperty(dim.parentCoarse)) {
        coarseTotals[dim.parentCoarse] += value;
      }
    });

    // Return as array in correct order
    return coarseOrder.map(id => coarseTotals[id] || 0);
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
            <Tooltip title={
              cacheStatus?.needsRegeneration
                ? `Cache outdated: ${cacheStatus.reason}`
                : cacheInfo
                  ? `Last generated: ${new Date(cacheInfo.generatedAt).toLocaleString()}`
                  : 'No cache generated yet'
            }>
              <Button
                icon={generatingCache ? <SyncOutlined spin /> : <DatabaseOutlined />}
                onClick={handleGenerateCache}
                loading={generatingCache}
                type={cacheStatus?.needsRegeneration ? 'primary' : 'default'}
                danger={cacheStatus?.needsRegeneration}
              >
                {cacheStatus?.needsRegeneration ? 'Regenerate Cache' : 'Generate Cache'}
              </Button>
            </Tooltip>
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
        title={
          <Space>
            {editingId && (
              <Button
                icon={<LeftOutlined />}
                disabled={getCurrentIndex(editingId) <= 0}
                onClick={() => handlePrevious(editingId, 'edit')}
              >
                Prev
              </Button>
            )}
            <span>{editingId ? `Edit Fulfillment Vector: ${editingId}` : 'Add Fulfillment Vector'}</span>
            {editingId && (
              <>
                <Tag color="blue">{getCurrentIndex(editingId) + 1} / {sortedCommodityIds.length}</Tag>
                <Button
                  icon={<RightOutlined />}
                  disabled={getCurrentIndex(editingId) >= sortedCommodityIds.length - 1}
                  onClick={() => handleNext(editingId, 'edit')}
                >
                  Next
                </Button>
              </>
            )}
          </Space>
        }
        open={isModalVisible}
        onOk={() => handleModalOk(false)}
        onCancel={() => {
          setIsModalVisible(false);
          form.resetFields();
        }}
        width={1200}
        footer={[
          <Button key="cancel" onClick={() => {
            setIsModalVisible(false);
            form.resetFields();
          }}>
            Cancel
          </Button>,
          editingId && (
            <Button key="view" icon={<EyeOutlined />} onClick={switchToView}>
              View
            </Button>
          ),
          <Button key="save" type="primary" onClick={() => handleModalOk(false)}>
            Save
          </Button>,
          <Button key="saveClose" onClick={() => handleModalOk(true)}>
            Save & Close
          </Button>,
        ]}
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
            <Col span={6}>
              <Form.Item
                name="durationCycles"
                label="Duration (cycles)"
                help="Cycles before expiry (leave empty for permanent)"
              >
                <InputNumber min={1} max={10000} style={{ width: '100%' }} placeholder="null = permanent" />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item
                name="effectDecayRate"
                label="Effect Decay Rate"
                help="Effectiveness loss per cycle (0 = no decay)"
              >
                <InputNumber min={0} max={1} step={0.001} style={{ width: '100%' }} />
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
              prevValues.fulfillmentVector?.fine !== currentValues.fulfillmentVector?.fine ||
              prevValues.id !== currentValues.id
            }
          >
            {() => (
              <VectorEditor
                key={`vector-editor-${editingId || 'new'}`}
                dimensions={dimensions.fineDimensions}
                values={fineObjectToArray(currentFulfillmentVector.fine || {})}
                onChange={(values) => {
                  const fineObj = fineArrayToObject(values);
                  const coarseArr = calculateCoarseFromFine(values);
                  setCurrentFulfillmentVector({
                    coarse: coarseArr,
                    fine: fineObj,
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
        title={
          <Space>
            {viewing && (
              <Button
                icon={<LeftOutlined />}
                disabled={getCurrentIndex(viewing.id) <= 0}
                onClick={() => handlePrevious(viewing.id, 'view')}
              >
                Prev
              </Button>
            )}
            <span>View Fulfillment Vector: {viewing?.id}</span>
            {viewing && (
              <>
                <Tag color="blue">{getCurrentIndex(viewing.id) + 1} / {sortedCommodityIds.length}</Tag>
                <Button
                  icon={<RightOutlined />}
                  disabled={getCurrentIndex(viewing.id) >= sortedCommodityIds.length - 1}
                  onClick={() => handleNext(viewing.id, 'view')}
                >
                  Next
                </Button>
              </>
            )}
          </Space>
        }
        open={isViewModalVisible}
        onCancel={() => setIsViewModalVisible(false)}
        footer={[
          <Button key="close" onClick={() => setIsViewModalVisible(false)}>
            Close
          </Button>,
          <Button key="edit" type="primary" icon={<EditOutlined />} onClick={switchToEdit}>
            Edit
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
                {(viewing.data.durability === 'durable' || viewing.data.durability === 'permanent') && (
                  <>
                    <Col span={12}>
                      <strong>Duration:</strong>{' '}
                      {viewing.data.durationCycles ? `${viewing.data.durationCycles} cycles` : 'Permanent'}
                    </Col>
                    <Col span={12}>
                      <strong>Effect Decay Rate:</strong>{' '}
                      {viewing.data.effectDecayRate ? `${(viewing.data.effectDecayRate * 100).toFixed(2)}% per cycle` : 'No decay'}
                    </Col>
                  </>
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
              values={viewing.data.fulfillmentVector?.coarse || new Array(9).fill(0)}
              title="Coarse Fulfillment Profile (9D)"
            />

            <VectorHeatmap
              dimensions={dimensions.fineDimensions}
              values={fineObjectToArray(viewing.data.fulfillmentVector?.fine || {})}
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

      {/* Cache Info Modal */}
      <Modal
        title={<Space><DatabaseOutlined /> Commodity Cache Generated</Space>}
        open={isCacheModalVisible}
        onCancel={() => setIsCacheModalVisible(false)}
        footer={[
          <Button key="close" type="primary" onClick={() => setIsCacheModalVisible(false)}>
            Close
          </Button>
        ]}
        width={600}
      >
        {cacheInfo && (
          <Space direction="vertical" style={{ width: '100%' }} size="large">
            <Card size="small" title="Cache Statistics">
              <Row gutter={[16, 16]}>
                <Col span={8}>
                  <Statistic title="Coarse Caches" value={cacheInfo.metadata.coarseCacheCount} />
                </Col>
                <Col span={8}>
                  <Statistic title="Fine Caches" value={cacheInfo.metadata.fineCacheCount} />
                </Col>
                <Col span={8}>
                  <Statistic title="Substitution Groups" value={cacheInfo.metadata.substitutionGroupCount} />
                </Col>
                <Col span={12}>
                  <Statistic title="Total Commodities" value={cacheInfo.metadata.totalCommodities} />
                </Col>
                <Col span={12}>
                  <Statistic
                    title="Generated At"
                    value={new Date(cacheInfo.generatedAt).toLocaleString()}
                    valueStyle={{ fontSize: '14px' }}
                  />
                </Col>
              </Row>
            </Card>

            <Card size="small" title="Source Data Hashes">
              <p><strong>Fulfillment Vectors:</strong> {cacheInfo.sourceDataHashes.fulfillmentVectors}</p>
              <p><strong>Dimension Definitions:</strong> {cacheInfo.sourceDataHashes.dimensionDefinitions}</p>
              <p><strong>Substitution Rules:</strong> {cacheInfo.sourceDataHashes.substitutionRules}</p>
            </Card>

            <Card size="small" title="Usage Info" style={{ background: '#f6ffed', borderColor: '#b7eb8f' }}>
              <p>
                The pre-computed cache is saved to <code>craving_system/commodity_cache.json</code>.
                The game will automatically load this cache on startup, reducing initialization time.
              </p>
              <p>
                <strong>Note:</strong> You should regenerate the cache whenever you modify:
              </p>
              <ul style={{ marginBottom: 0 }}>
                <li>Fulfillment vectors (this manager)</li>
                <li>Dimension definitions</li>
                <li>Substitution rules</li>
              </ul>
            </Card>
          </Space>
        )}
      </Modal>
    </div>
  );
};

export default FulfillmentVectorManager;
