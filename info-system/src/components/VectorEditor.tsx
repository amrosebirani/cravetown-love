import { useState, useEffect } from 'react';
import { Card, Slider, InputNumber, Row, Col, Typography, Space, Button, Collapse, Badge } from 'antd';
import type { FineDimension } from '../types';

const { Text, Title } = Typography;
const { Panel } = Collapse;

interface VectorEditorProps {
  dimensions: FineDimension[];
  values: number[];
  onChange: (values: number[]) => void;
  min?: number;
  max?: number;
  step?: number;
  title?: string;
  showCoarseView?: boolean;
  groupByParent?: boolean;
}

const VectorEditor: React.FC<VectorEditorProps> = ({
  dimensions,
  values,
  onChange,
  min = 0,
  max = 10,
  step = 0.1,
  title = 'Vector Editor',
  showCoarseView = true,
  groupByParent = true,
}) => {
  const [localValues, setLocalValues] = useState<number[]>(values);

  useEffect(() => {
    setLocalValues(values);
  }, [values]);

  const handleChange = (index: number, value: number | null) => {
    if (value === null) return;

    const newValues = [...localValues];
    newValues[index] = value;
    setLocalValues(newValues);
    onChange(newValues);
  };

  const handleResetAll = () => {
    const resetValues = new Array(dimensions.length).fill(0);
    setLocalValues(resetValues);
    onChange(resetValues);
  };

  const handleSetAll = (value: number) => {
    const newValues = new Array(dimensions.length).fill(value);
    setLocalValues(newValues);
    onChange(newValues);
  };

  // Calculate coarse aggregates
  const calculateCoarseAggregates = () => {
    const coarseGroups: Record<string, { sum: number; count: number; name: string }> = {};

    dimensions.forEach((dim, index) => {
      if (!coarseGroups[dim.parentCoarse]) {
        coarseGroups[dim.parentCoarse] = { sum: 0, count: 0, name: dim.parentCoarse };
      }
      coarseGroups[dim.parentCoarse].sum += localValues[index] || 0;
      coarseGroups[dim.parentCoarse].count += 1;
    });

    return Object.entries(coarseGroups).map(([key, data]) => ({
      id: key,
      name: data.name,
      average: data.sum / data.count,
      total: data.sum,
    }));
  };

  // Group dimensions by parent coarse category
  const groupedDimensions = () => {
    const groups: Record<string, { dimensions: FineDimension[]; indices: number[] }> = {};

    dimensions.forEach((dim, index) => {
      if (!groups[dim.parentCoarse]) {
        groups[dim.parentCoarse] = { dimensions: [], indices: [] };
      }
      groups[dim.parentCoarse].dimensions.push(dim);
      groups[dim.parentCoarse].indices.push(index);
    });

    return groups;
  };

  const coarseAggregates = showCoarseView ? calculateCoarseAggregates() : [];
  const groups = groupByParent ? groupedDimensions() : null;

  const renderSlider = (dim: FineDimension, index: number) => {
    const value = localValues[index] || 0;
    const isNonZero = value > 0.01;

    return (
      <Row key={dim.id} gutter={16} style={{ marginBottom: 12 }}>
        <Col span={8}>
          <Text strong={isNonZero} style={{ color: isNonZero ? '#1890ff' : undefined }}>
            {dim.name}
          </Text>
          <br />
          <Text type="secondary" style={{ fontSize: '11px' }}>
            {dim.tags.join(', ')}
          </Text>
        </Col>
        <Col span={12}>
          <Slider
            min={min}
            max={max}
            step={step}
            value={value}
            onChange={(val) => handleChange(index, val)}
            marks={{
              [min]: min.toString(),
              [(min + max) / 2]: ((min + max) / 2).toFixed(1),
              [max]: max.toString(),
            }}
          />
        </Col>
        <Col span={4}>
          <InputNumber
            min={min}
            max={max}
            step={step}
            value={value}
            onChange={(val) => handleChange(index, val)}
            style={{ width: '100%' }}
          />
        </Col>
      </Row>
    );
  };

  return (
    <Card
      title={
        <Space>
          <span>{title}</span>
          <Badge count={localValues.filter(v => v > 0.01).length} showZero />
        </Space>
      }
      extra={
        <Space>
          <Button size="small" onClick={() => handleSetAll(1)}>Set All to 1</Button>
          <Button size="small" onClick={() => handleSetAll(min)}>Set All to {min}</Button>
          <Button size="small" danger onClick={handleResetAll}>Reset All</Button>
        </Space>
      }
    >
      {showCoarseView && coarseAggregates.length > 0 && (
        <Card
          size="small"
          title="Coarse Aggregates (Average per Category)"
          style={{ marginBottom: 16, background: '#f0f2f5' }}
        >
          <Row gutter={[16, 8]}>
            {coarseAggregates.map((agg) => (
              <Col span={8} key={agg.id}>
                <Card size="small" style={{ textAlign: 'center' }}>
                  <Text type="secondary" style={{ fontSize: '11px' }}>
                    {agg.name}
                  </Text>
                  <br />
                  <Text strong style={{ fontSize: '18px', color: '#1890ff' }}>
                    {agg.average.toFixed(2)}
                  </Text>
                  <br />
                  <Text type="secondary" style={{ fontSize: '10px' }}>
                    (total: {agg.total.toFixed(1)})
                  </Text>
                </Card>
              </Col>
            ))}
          </Row>
        </Card>
      )}

      {groupByParent && groups ? (
        <Collapse defaultActiveKey={Object.keys(groups).slice(0, 2)}>
          {Object.entries(groups).map(([parentId, group]) => {
            const activeCount = group.indices.filter(i => localValues[i] > 0.01).length;
            return (
              <Panel
                header={
                  <Space>
                    <Text strong>{parentId}</Text>
                    <Badge count={activeCount} />
                  </Space>
                }
                key={parentId}
              >
                {group.dimensions.map((dim, idx) =>
                  renderSlider(dim, group.indices[idx])
                )}
              </Panel>
            );
          })}
        </Collapse>
      ) : (
        <div style={{ maxHeight: '600px', overflowY: 'auto' }}>
          {dimensions.map((dim, index) => renderSlider(dim, index))}
        </div>
      )}
    </Card>
  );
};

export default VectorEditor;
