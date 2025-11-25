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
  maxValue = 10,
}) => {
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
        max: maxValue,
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
    area: {},
    point: {
      size: 3,
    },
  };

  return (
    <Card title={title} size="small">
      <Radar {...config} height={400} />
    </Card>
  );
};

export default VectorVisualization;
