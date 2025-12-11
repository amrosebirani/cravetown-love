import { Card } from 'antd';
import { Radar } from '@ant-design/plots';
import type { CoarseDimension } from '../types';

interface VectorVisualizationProps {
  dimensions: CoarseDimension[];
  values: number[];
  title?: string;
  comparisonValues?: { label: string; values: number[] }[];
  maxValue?: number;
}

const VectorVisualization: React.FC<VectorVisualizationProps> = ({
  dimensions,
  values,
  title = 'Craving Profile',
  comparisonValues = [],
  maxValue,
}) => {
  // Calculate dynamic max if not provided
  const allValues = [...values, ...comparisonValues.flatMap(c => c.values)];
  const calculatedMax = Math.max(...allValues, 1);
  const effectiveMax = maxValue ?? Math.ceil(calculatedMax * 1.2); // 20% headroom
  // Prepare data for radar chart
  const prepareData = () => {
    const data: any[] = [];

    // Main values
    dimensions.forEach((dim, index) => {
      data.push({
        dimension: dim.name,
        value: values[index] || 0,
        category: 'Current',
      });
    });

    // Comparison values
    comparisonValues.forEach((comparison) => {
      dimensions.forEach((dim, index) => {
        data.push({
          dimension: dim.name,
          value: comparison.values[index] || 0,
          category: comparison.label,
        });
      });
    });

    return data;
  };

  const config = {
    data: prepareData(),
    xField: 'dimension',
    yField: 'value',
    seriesField: 'category',
    meta: {
      value: {
        alias: 'Craving Value',
        min: 0,
        max: effectiveMax,
      },
    },
    xAxis: {
      line: null,
      tickLine: null,
      grid: {
        line: {
          style: {
            lineDash: null,
          },
        },
      },
    },
    yAxis: {
      line: null,
      tickLine: null,
      grid: {
        line: {
          type: 'line',
          style: {
            lineDash: null,
          },
        },
      },
    },
    area: {
      style: {
        fillOpacity: 0.3,
      },
    },
    point: {
      size: 4,
      shape: 'circle',
      style: {
        fill: '#5B8FF9',
        stroke: '#5B8FF9',
        lineWidth: 2,
      },
    },
    line: {
      style: {
        lineWidth: 2,
      },
    },
    legend: false,  // Hide legend for single series
  };

  return (
    <Card title={title} size="small">
      <Radar {...config} height={400} />
    </Card>
  );
};

export default VectorVisualization;
