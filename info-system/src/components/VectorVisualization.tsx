import { Card } from 'antd';
import { Radar } from '@ant-design/plots';
import type { CoarseDimension } from '../types';
import { useMemo, useRef, useEffect } from 'react';

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
  // Ref to hold chart instance for cleanup
  const chartRef = useRef<any>(null);

  // Ensure values and dimensions are arrays (handle null/undefined)
  const safeValues = values ?? [];
  const safeDimensions = dimensions ?? [];
  const safeComparisonValues = comparisonValues ?? [];

  // Cleanup chart on unmount to prevent memory leaks
  useEffect(() => {
    return () => {
      if (chartRef.current) {
        try {
          chartRef.current.destroy?.();
        } catch (e) {
          // Chart may already be destroyed
        }
        chartRef.current = null;
      }
    };
  }, []);

  // Calculate dynamic max if not provided - memoized
  const effectiveMax = useMemo(() => {
    const allValues = [...safeValues, ...safeComparisonValues.flatMap(c => c.values ?? [])];
    const calculatedMax = Math.max(...allValues, 1);
    return maxValue ?? Math.ceil(calculatedMax * 1.2); // 20% headroom
  }, [safeValues, safeComparisonValues, maxValue]);

  // Prepare data for radar chart - memoized to prevent unnecessary re-renders
  const chartData = useMemo(() => {
    const data: any[] = [];

    // Main values
    safeDimensions.forEach((dim, index) => {
      data.push({
        dimension: dim.name,
        value: safeValues[index] || 0,
        category: 'Current',
      });
    });

    // Comparison values
    safeComparisonValues.forEach((comparison) => {
      safeDimensions.forEach((dim, index) => {
        data.push({
          dimension: dim.name,
          value: (comparison.values ?? [])[index] || 0,
          category: comparison.label,
        });
      });
    });

    return data;
  }, [safeDimensions, safeValues, safeComparisonValues]);

  // Memoize config to prevent re-creating on every render
  const config = useMemo(() => ({
    data: chartData,
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
    // Get chart ref for cleanup
    onReady: (chart: any) => {
      chartRef.current = chart;
    },
  }), [chartData, effectiveMax]);

  // Don't render chart if no dimensions
  if (safeDimensions.length === 0) {
    return (
      <Card title={title} size="small">
        <div style={{ height: 400, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#999' }}>
          No dimensions available
        </div>
      </Card>
    );
  }

  return (
    <Card title={title} size="small">
      <Radar {...config} height={400} />
    </Card>
  );
};

export default VectorVisualization;
