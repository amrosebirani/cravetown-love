import { useState, useEffect } from 'react';
import { Card, Slider, InputNumber, Row, Col, Typography, Space, Button, Collapse, Badge } from 'antd';
import { CloseCircleOutlined } from '@ant-design/icons';
import type { FineDimension } from '../types';

const { Text, Title } = Typography;
const { Panel } = Collapse;

interface VectorEditorProps {
  dimensions: FineDimension[];
  values?: number[];  // Legacy prop - prefer using 'value' for Ant Design Form compatibility
  value?: number[];   // Ant Design Form controlled component prop
  onChange?: (values: number[]) => void;  // Optional - Ant Design Form injects this automatically
  min?: number;
  max?: number;
  step?: number;
  title?: string;
  showCoarseView?: boolean;
  groupByParent?: boolean;
}

const VectorEditor: React.FC<VectorEditorProps> = ({
  dimensions,
  values: valuesProp,
  value: valueProp,  // Ant Design Form passes this
  onChange,
  min = 0,
  max = 10,
  step = 0.1,
  title = 'Vector Editor',
  showCoarseView = true,
  groupByParent = true,
}) => {
  // Calculate the max index from dimensions to size the array correctly
  const maxDimensionIndex = Math.max(...dimensions.map(d => d.index), 0);
  const requiredArraySize = maxDimensionIndex + 1;

  // Support both 'value' (Ant Design Form) and 'values' (legacy) props
  // Ensure array is sized to accommodate all dimension indices
  const rawExternalValues = valueProp ?? valuesProp ?? [];
  const externalValues = [...rawExternalValues];
  // Extend array if needed to cover all dimension indices
  while (externalValues.length < requiredArraySize) {
    externalValues.push(0);
  }

  const [localValues, setLocalValues] = useState<number[]>(externalValues);

  // Sync local state when external values change (e.g., when form resets or loads new data)
  // This is needed because Ant Design Form may update 'value' prop after initial render
  useEffect(() => {
    // Extend incoming values to required size
    const extendedValues = [...(valueProp ?? valuesProp ?? [])];
    while (extendedValues.length < requiredArraySize) {
      extendedValues.push(0);
    }
    if (JSON.stringify(localValues) !== JSON.stringify(extendedValues)) {
      setLocalValues(extendedValues);
    }
  }, [valueProp, valuesProp, requiredArraySize]);

  const handleChange = (dimensionIndex: number, value: number | null) => {
    // Treat null as 0 (when user clears the input)
    const actualValue = value ?? 0;

    const newValues = [...localValues];
    // Ensure array is large enough for this index
    while (newValues.length <= dimensionIndex) {
      newValues.push(0);
    }
    newValues[dimensionIndex] = actualValue;
    setLocalValues(newValues);
    onChange?.(newValues);
  };

  const handleResetAll = () => {
    const resetValues = new Array(requiredArraySize).fill(0);
    setLocalValues(resetValues);
    onChange?.(resetValues);
  };

  const handleSetAll = (value: number) => {
    // Only set values for actual dimensions, leave gaps as 0
    const newValues = new Array(requiredArraySize).fill(0);
    dimensions.forEach(dim => {
      newValues[dim.index] = value;
    });
    setLocalValues(newValues);
    onChange?.(newValues);
  };

  // Calculate coarse aggregates
  const calculateCoarseAggregates = () => {
    const coarseGroups: Record<string, { sum: number; count: number; name: string }> = {};

    dimensions.forEach((dim) => {
      if (!coarseGroups[dim.parentCoarse]) {
        coarseGroups[dim.parentCoarse] = { sum: 0, count: 0, name: dim.parentCoarse };
      }
      // Use dim.index to access the correct value in the array
      coarseGroups[dim.parentCoarse].sum += localValues[dim.index] || 0;
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
    const groups: Record<string, { dimensions: FineDimension[] }> = {};

    dimensions.forEach((dim) => {
      if (!groups[dim.parentCoarse]) {
        groups[dim.parentCoarse] = { dimensions: [] };
      }
      groups[dim.parentCoarse].dimensions.push(dim);
    });

    return groups;
  };

  const coarseAggregates = showCoarseView ? calculateCoarseAggregates() : [];
  const groups = groupByParent ? groupedDimensions() : null;

  // Render a slider for a dimension - uses dim.index to access the value array
  const renderSlider = (dim: FineDimension) => {
    const dimIndex = dim.index;
    const value = localValues[dimIndex] || 0;
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
        <Col span={10}>
          <Slider
            min={min}
            max={max}
            step={step}
            value={value}
            onChange={(val) => handleChange(dimIndex, val)}
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
            onChange={(val) => handleChange(dimIndex, val)}
            style={{ width: '100%' }}
          />
        </Col>
        <Col span={2}>
          <button
            type="button"
            disabled={value === 0}
            style={{
              background: value === 0 ? '#ccc' : '#ff4d4f',
              color: 'white',
              border: 'none',
              borderRadius: '4px',
              padding: '4px 8px',
              cursor: value === 0 ? 'not-allowed' : 'pointer',
            }}
            onClick={() => handleChange(dimIndex, 0)}
          >
            ×
          </button>
        </Col>
      </Row>
    );
  };

  // Count non-zero values only for dimensions that exist (not gaps in the array)
  const nonZeroCount = dimensions.filter(dim => (localValues[dim.index] || 0) > 0.01).length;

  return (
    <Card
      title={
        <Space>
          <span>{title}</span>
          <Badge count={nonZeroCount} showZero />
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
            // Count non-zero values using dimension indices
            const activeCount = group.dimensions.filter(dim => (localValues[dim.index] || 0) > 0.01).length;
            return (
              <Panel
                header={
                  <Space>
                    <Text strong>{parentId}</Text>
                    <Badge count={activeCount} />
                  </Space>
                }
                key={parentId}
                forceRender={true}
              >
                <div onClick={(e) => e.stopPropagation()}>
                  {group.dimensions.map((dim) => renderSlider(dim))}
                </div>
              </Panel>
            );
          })}
        </Collapse>
      ) : (
        <div style={{ maxHeight: '600px', overflowY: 'auto' }}>
          {dimensions.map((dim) => renderSlider(dim))}
        </div>
      )}
    </Card>
  );
};

export default VectorEditor;
