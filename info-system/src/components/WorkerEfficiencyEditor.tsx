import { InputNumber, Space, Typography, Divider } from 'antd';

const { Text } = Typography;

interface WorkerEfficiencyEditorProps {
  workCategories: string[];
  efficiencies: Record<string, number>;
  onChange: (efficiencies: Record<string, number>) => void;
}

const WorkerEfficiencyEditor = ({ workCategories, efficiencies, onChange }: WorkerEfficiencyEditorProps) => {
  const handleEfficiencyChange = (category: string, value: number | null) => {
    const newEfficiencies = { ...efficiencies };
    if (value !== null) {
      newEfficiencies[category] = value;
    } else {
      delete newEfficiencies[category];
    }
    onChange(newEfficiencies);
  };

  if (!workCategories || workCategories.length === 0) {
    return (
      <div style={{ padding: '12px', background: '#f5f5f5', borderRadius: '4px' }}>
        <Text type="secondary">Select work categories first to set efficiencies</Text>
      </div>
    );
  }

  return (
    <div style={{ padding: '12px', background: '#f9f9f9', borderRadius: '4px' }}>
      <Text strong>Worker Efficiency by Category</Text>
      <Text type="secondary" style={{ display: 'block', marginBottom: '12px', fontSize: '12px' }}>
        Set efficiency multiplier for each work category (0.0 - 1.0). Higher values = more productive.
      </Text>
      <Divider style={{ margin: '8px 0' }} />
      <Space direction="vertical" style={{ width: '100%' }}>
        {workCategories.map(category => (
          <div key={category} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Text>{category}:</Text>
            <InputNumber
              min={0.0}
              max={1.0}
              step={0.1}
              value={efficiencies[category] || 0.5}
              onChange={(value) => handleEfficiencyChange(category, value)}
              style={{ width: '100px' }}
              placeholder="0.5"
            />
          </div>
        ))}
      </Space>
    </div>
  );
};

export default WorkerEfficiencyEditor;
