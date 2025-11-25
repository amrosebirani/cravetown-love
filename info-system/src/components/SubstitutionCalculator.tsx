import { useState, useEffect, useMemo } from 'react';
import { Card, Table, Select, Space, Statistic, Row, Col, Tag, Slider, Alert } from 'antd';
import { ThunderboltOutlined, FireOutlined } from '@ant-design/icons';
import type { FulfillmentVectorsData, CommoditiesData, DimensionDefinitions, CommodityFulfillment, Commodity } from '../types';
import { loadFulfillmentVectors, loadCommodities, loadDimensionDefinitions } from '../api';

interface SimilarityResult {
  commodityId: string;
  commodityName: string;
  category: string;
  similarity: number;
  cosineSimilarity: number;
  euclideanDistance: number;
}

const SubstitutionCalculator: React.FC = () => {
  const [fulfillmentData, setFulfillmentData] = useState<FulfillmentVectorsData | null>(null);
  const [commoditiesData, setCommoditiesData] = useState<CommoditiesData | null>(null);
  const [dimensions, setDimensions] = useState<DimensionDefinitions | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedCommodity, setSelectedCommodity] = useState<string | null>(null);
  const [similarityThreshold, setSimilarityThreshold] = useState<number>(0.5);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [fulfillment, commodities, dims] = await Promise.all([
        loadFulfillmentVectors(),
        loadCommodities(),
        loadDimensionDefinitions()
      ]);
      setFulfillmentData(fulfillment);
      setCommoditiesData(commodities);
      setDimensions(dims);
    } catch (error) {
      console.error('Failed to load data:', error);
    } finally {
      setLoading(false);
    }
  };

  // Calculate cosine similarity between two fine vectors
  const calculateCosineSimilarity = (vec1: Record<string, number>, vec2: Record<string, number>): number => {
    const keys = new Set([...Object.keys(vec1), ...Object.keys(vec2)]);
    let dotProduct = 0;
    let mag1 = 0;
    let mag2 = 0;

    keys.forEach(key => {
      const v1 = vec1[key] || 0;
      const v2 = vec2[key] || 0;
      dotProduct += v1 * v2;
      mag1 += v1 * v1;
      mag2 += v2 * v2;
    });

    const magnitude1 = Math.sqrt(mag1);
    const magnitude2 = Math.sqrt(mag2);

    if (magnitude1 === 0 || magnitude2 === 0) return 0;
    return dotProduct / (magnitude1 * magnitude2);
  };

  // Calculate Euclidean distance between two fine vectors
  const calculateEuclideanDistance = (vec1: Record<string, number>, vec2: Record<string, number>): number => {
    const keys = new Set([...Object.keys(vec1), ...Object.keys(vec2)]);
    let sumSquares = 0;

    keys.forEach(key => {
      const v1 = vec1[key] || 0;
      const v2 = vec2[key] || 0;
      sumSquares += (v1 - v2) * (v1 - v2);
    });

    return Math.sqrt(sumSquares);
  };

  // Calculate similarity results for selected commodity
  const similarityResults = useMemo(() => {
    if (!selectedCommodity || !fulfillmentData || !commoditiesData) return [];

    const selectedFulfillment = fulfillmentData.commodities[selectedCommodity];
    if (!selectedFulfillment) return [];

    const results: SimilarityResult[] = [];

    Object.entries(fulfillmentData.commodities).forEach(([id, fulfillment]) => {
      if (id === selectedCommodity) return; // Skip self

      const commodity = commoditiesData.commodities.find(c => c.id === id);
      if (!commodity) return;

      const cosineSim = calculateCosineSimilarity(
        selectedFulfillment.fulfillmentVector.fine,
        fulfillment.fulfillmentVector.fine
      );

      const euclideanDist = calculateEuclideanDistance(
        selectedFulfillment.fulfillmentVector.fine,
        fulfillment.fulfillmentVector.fine
      );

      // Normalized similarity (0-1, based on both metrics)
      // Higher cosine = more similar direction
      // Lower euclidean = more similar magnitude
      const maxDistance = 100; // Reasonable upper bound for euclidean distance
      const normalizedDistance = 1 - Math.min(euclideanDist / maxDistance, 1);
      const similarity = (cosineSim * 0.7 + normalizedDistance * 0.3);

      results.push({
        commodityId: id,
        commodityName: commodity.name,
        category: commodity.category,
        similarity,
        cosineSimilarity: cosineSim,
        euclideanDistance: euclideanDist,
      });
    });

    // Sort by similarity descending
    return results.sort((a, b) => b.similarity - a.similarity);
  }, [selectedCommodity, fulfillmentData, commoditiesData]);

  // Filter by threshold
  const filteredResults = useMemo(() => {
    return similarityResults.filter(r => r.similarity >= similarityThreshold);
  }, [similarityResults, similarityThreshold]);

  const getSimilarityColor = (similarity: number): string => {
    if (similarity >= 0.9) return 'red';
    if (similarity >= 0.7) return 'orange';
    if (similarity >= 0.5) return 'gold';
    if (similarity >= 0.3) return 'blue';
    return 'default';
  };

  const getSimilarityLabel = (similarity: number): string => {
    if (similarity >= 0.9) return 'Excellent';
    if (similarity >= 0.7) return 'Good';
    if (similarity >= 0.5) return 'Moderate';
    if (similarity >= 0.3) return 'Weak';
    return 'Poor';
  };

  const columns = [
    {
      title: 'Rank',
      key: 'rank',
      width: 70,
      render: (_: any, __: any, index: number) => index + 1,
    },
    {
      title: 'Commodity',
      dataIndex: 'commodityName',
      key: 'commodityName',
      width: 200,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 150,
      render: (category: string) => <Tag>{category}</Tag>,
    },
    {
      title: 'Overall Similarity',
      dataIndex: 'similarity',
      key: 'similarity',
      width: 180,
      align: 'center' as const,
      render: (similarity: number) => (
        <Space>
          <Tag color={getSimilarityColor(similarity)}>
            {getSimilarityLabel(similarity)}
          </Tag>
          <span>{(similarity * 100).toFixed(1)}%</span>
        </Space>
      ),
      sorter: (a: SimilarityResult, b: SimilarityResult) => b.similarity - a.similarity,
    },
    {
      title: 'Cosine Similarity',
      dataIndex: 'cosineSimilarity',
      key: 'cosineSimilarity',
      width: 150,
      align: 'center' as const,
      render: (value: number) => (value * 100).toFixed(1) + '%',
    },
    {
      title: 'Euclidean Distance',
      dataIndex: 'euclideanDistance',
      key: 'euclideanDistance',
      width: 150,
      align: 'center' as const,
      render: (value: number) => value.toFixed(2),
    },
  ];

  if (loading || !fulfillmentData || !commoditiesData || !dimensions) {
    return <div>Loading...</div>;
  }

  const commoditiesWithFulfillment = commoditiesData.commodities.filter(
    c => fulfillmentData.commodities[c.id]
  );

  const selectedCommodityData = selectedCommodity
    ? commoditiesData.commodities.find(c => c.id === selectedCommodity)
    : null;

  return (
    <div>
      <Card
        title={
          <Space>
            <ThunderboltOutlined />
            <span>Substitution Calculator</span>
          </Space>
        }
      >
        <Space direction="vertical" style={{ width: '100%' }} size="large">
          <Alert
            message="How it works"
            description="This calculator compares commodities based on their fulfillment vectors to find substitutes. Higher similarity means commodities fulfill similar needs and can potentially substitute for each other in consumption."
            type="info"
            showIcon
          />

          <Card size="small">
            <Space direction="vertical" style={{ width: '100%' }}>
              <div>
                <strong>Select Commodity:</strong>
              </div>
              <Select
                style={{ width: '100%' }}
                placeholder="Select a commodity to analyze"
                value={selectedCommodity}
                onChange={setSelectedCommodity}
                showSearch
                filterOption={(input, option) =>
                  (option?.children as string).toLowerCase().includes(input.toLowerCase())
                }
              >
                {commoditiesWithFulfillment.map(c => (
                  <Select.Option key={c.id} value={c.id}>
                    {c.name} ({c.category})
                  </Select.Option>
                ))}
              </Select>
            </Space>
          </Card>

          {selectedCommodity && selectedCommodityData && (
            <>
              <Card size="small">
                <Row gutter={16}>
                  <Col span={8}>
                    <Statistic
                      title="Selected Commodity"
                      value={selectedCommodityData.name}
                      prefix={<FireOutlined />}
                    />
                  </Col>
                  <Col span={8}>
                    <Statistic
                      title="Category"
                      value={selectedCommodityData.category}
                    />
                  </Col>
                  <Col span={8}>
                    <Statistic
                      title="Similar Commodities Found"
                      value={filteredResults.length}
                      suffix={`/ ${similarityResults.length}`}
                    />
                  </Col>
                </Row>
              </Card>

              <Card size="small">
                <Space direction="vertical" style={{ width: '100%' }}>
                  <div>
                    <strong>Similarity Threshold: {(similarityThreshold * 100).toFixed(0)}%</strong>
                  </div>
                  <Slider
                    min={0}
                    max={1}
                    step={0.05}
                    value={similarityThreshold}
                    onChange={setSimilarityThreshold}
                    marks={{
                      0: '0%',
                      0.3: '30%',
                      0.5: '50%',
                      0.7: '70%',
                      0.9: '90%',
                      1: '100%',
                    }}
                  />
                </Space>
              </Card>

              <Table
                columns={columns}
                dataSource={filteredResults}
                rowKey="commodityId"
                loading={loading}
                scroll={{ x: 1000 }}
                pagination={{ pageSize: 20 }}
              />
            </>
          )}

          {!selectedCommodity && (
            <Alert
              message="Select a commodity to begin"
              description="Choose a commodity from the dropdown above to see which other commodities have similar fulfillment profiles and could potentially substitute for it."
              type="warning"
              showIcon
            />
          )}
        </Space>
      </Card>
    </div>
  );
};

export default SubstitutionCalculator;
