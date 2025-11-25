import { Card, Tooltip, Row, Col } from 'antd';
import type { FineDimension } from '../types';

interface VectorHeatmapProps {
  dimensions: FineDimension[];
  values: number[];
  title?: string;
  minValue?: number;
  maxValue?: number;
  colorScheme?: 'blue' | 'green' | 'red' | 'purple';
}

const VectorHeatmap: React.FC<VectorHeatmapProps> = ({
  dimensions,
  values,
  title = 'Vector Heatmap',
  minValue = 0,
  maxValue = 10,
  colorScheme = 'blue',
}) => {
  const getColor = (value: number): string => {
    const normalized = Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue)));

    const schemes = {
      blue: [
        `rgba(227, 242, 253, ${0.3 + normalized * 0.7})`,
        `rgba(144, 202, 249, ${0.3 + normalized * 0.7})`,
        `rgba(66, 165, 245, ${0.3 + normalized * 0.7})`,
        `rgba(33, 150, 243, ${0.3 + normalized * 0.7})`,
        `rgba(21, 101, 192, ${0.3 + normalized * 0.7})`,
      ],
      green: [
        `rgba(232, 245, 233, ${0.3 + normalized * 0.7})`,
        `rgba(165, 214, 167, ${0.3 + normalized * 0.7})`,
        `rgba(102, 187, 106, ${0.3 + normalized * 0.7})`,
        `rgba(76, 175, 80, ${0.3 + normalized * 0.7})`,
        `rgba(56, 142, 60, ${0.3 + normalized * 0.7})`,
      ],
      red: [
        `rgba(255, 235, 238, ${0.3 + normalized * 0.7})`,
        `rgba(239, 154, 154, ${0.3 + normalized * 0.7})`,
        `rgba(239, 83, 80, ${0.3 + normalized * 0.7})`,
        `rgba(244, 67, 54, ${0.3 + normalized * 0.7})`,
        `rgba(198, 40, 40, ${0.3 + normalized * 0.7})`,
      ],
      purple: [
        `rgba(243, 229, 245, ${0.3 + normalized * 0.7})`,
        `rgba(206, 147, 216, ${0.3 + normalized * 0.7})`,
        `rgba(171, 71, 188, ${0.3 + normalized * 0.7})`,
        `rgba(142, 36, 170, ${0.3 + normalized * 0.7})`,
        `rgba(106, 27, 154, ${0.3 + normalized * 0.7})`,
      ],
    };

    const colorArray = schemes[colorScheme];
    const index = Math.floor(normalized * (colorArray.length - 1));
    return colorArray[index];
  };

  // Group by parent coarse
  const groupedDimensions = dimensions.reduce((acc, dim, index) => {
    if (!acc[dim.parentCoarse]) {
      acc[dim.parentCoarse] = [];
    }
    acc[dim.parentCoarse].push({ dimension: dim, index });
    return acc;
  }, {} as Record<string, Array<{ dimension: FineDimension; index: number }>>);

  return (
    <Card title={title} size="small">
      <div style={{ padding: '8px' }}>
        {Object.entries(groupedDimensions).map(([parentId, items]) => (
          <div key={parentId} style={{ marginBottom: 16 }}>
            <div style={{
              fontSize: '12px',
              fontWeight: 'bold',
              marginBottom: 8,
              color: '#595959',
              textTransform: 'uppercase'
            }}>
              {parentId}
            </div>
            <Row gutter={[4, 4]}>
              {items.map(({ dimension, index }) => {
                const value = values[index] || 0;
                const isActive = value > 0.01;

                return (
                  <Col key={dimension.id} span={4}>
                    <Tooltip
                      title={
                        <div>
                          <div><strong>{dimension.name}</strong></div>
                          <div>Value: {value.toFixed(2)}</div>
                          <div>Tags: {dimension.tags.join(', ')}</div>
                        </div>
                      }
                    >
                      <div
                        style={{
                          background: getColor(value),
                          border: isActive ? '2px solid #1890ff' : '1px solid #d9d9d9',
                          borderRadius: 4,
                          padding: '8px 4px',
                          textAlign: 'center',
                          cursor: 'pointer',
                          height: '60px',
                          display: 'flex',
                          flexDirection: 'column',
                          justifyContent: 'center',
                          transition: 'all 0.2s',
                        }}
                      >
                        <div style={{
                          fontSize: '10px',
                          color: isActive ? '#000' : '#8c8c8c',
                          fontWeight: isActive ? 'bold' : 'normal',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}>
                          {dimension.name}
                        </div>
                        {isActive && (
                          <div style={{
                            fontSize: '14px',
                            fontWeight: 'bold',
                            color: '#1890ff',
                            marginTop: 2,
                          }}>
                            {value.toFixed(1)}
                          </div>
                        )}
                      </div>
                    </Tooltip>
                  </Col>
                );
              })}
            </Row>
          </div>
        ))}
      </div>

      {/* Legend */}
      <div style={{
        marginTop: 16,
        paddingTop: 12,
        borderTop: '1px solid #f0f0f0',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
      }}>
        <span style={{ fontSize: '12px', color: '#8c8c8c' }}>Low</span>
        <div style={{ display: 'flex', gap: 2 }}>
          {[0, 0.25, 0.5, 0.75, 1].map((val, i) => (
            <div
              key={i}
              style={{
                width: 40,
                height: 20,
                background: getColor(val * maxValue),
                border: '1px solid #d9d9d9',
              }}
            />
          ))}
        </div>
        <span style={{ fontSize: '12px', color: '#8c8c8c' }}>High</span>
      </div>
    </Card>
  );
};

export default VectorHeatmap;
