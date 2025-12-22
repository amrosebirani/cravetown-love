import { useState, useEffect } from 'react';
import { Form, InputNumber, Select, Tag, Space, message } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import type { WorkerRequirements } from '../types';
import { loadWorkerTypes } from '../api';

interface WorkerEditorProps {
  workers?: WorkerRequirements;
  onChange: (workers: WorkerRequirements) => void;
}

const WorkerEditor = ({ workers, onChange }: WorkerEditorProps) => {
  const [workerTypeOptions, setWorkerTypeOptions] = useState<Array<{ value: string; label: string }>>([]);
  const [_messageApi, contextHolder] = message.useMessage();

  // Provide default workers if undefined
  const currentWorkers: WorkerRequirements = workers || {
    required: 1,
    max: 3,
    vocations: [],
    efficiencyBonus: 0.1,
    wages: 0
  };

  useEffect(() => {
    loadWorkerTypeOptions();
  }, []);

  const loadWorkerTypeOptions = async () => {
    try {
      const data = await loadWorkerTypes();
      const options = data.workerTypes.map(wt => ({
        value: wt.id,
        label: `${wt.name} (${wt.category})`
      }));
      setWorkerTypeOptions(options);
    } catch (error) {
      console.error('Failed to load worker types:', error);
      // Silently fail, user can still type custom vocations
    }
  };

  const handleChange = (field: keyof WorkerRequirements, value: any) => {
    onChange({
      ...currentWorkers,
      [field]: value
    });
  };

  return (
    <>
      {contextHolder}
      <Space direction="vertical" style={{ width: '100%' }} size="middle">
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
          <Form.Item
            label="Required Workers"
            required
            style={{ marginBottom: 0 }}
          >
            <InputNumber
              min={0}
              value={currentWorkers.required}
              onChange={(value) => handleChange('required', value || 0)}
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item
            label="Max Workers"
            required
            style={{ marginBottom: 0 }}
          >
            <InputNumber
              min={currentWorkers.required}
              value={currentWorkers.max}
              onChange={(value) => handleChange('max', value || currentWorkers.required)}
              style={{ width: '100%' }}
            />
          </Form.Item>
        </div>

        <Form.Item
          label="Efficiency Bonus"
          tooltip="Per additional worker above required (e.g., 0.15 = 15% boost per worker)"
          style={{ marginBottom: 0 }}
        >
          <InputNumber
            min={0}
            max={1}
            step={0.01}
            value={currentWorkers.efficiencyBonus}
            onChange={(value) => handleChange('efficiencyBonus', value || 0)}
            style={{ width: '100%' }}
            formatter={(value) => `${(Number(value) * 100).toFixed(0)}%`}
            parser={(value) => Number(value?.replace('%', '')) / 100}
          />
        </Form.Item>

        <Form.Item
          label="Worker Vocations"
          tooltip="Worker types that can work at this building (from Worker Types tab)"
          style={{ marginBottom: 0 }}
        >
          <Select
            mode="tags"
            value={currentWorkers.vocations}
            onChange={(value) => handleChange('vocations', value)}
            placeholder="Select worker types or type custom vocations"
            style={{ width: '100%' }}
            options={workerTypeOptions}
            dropdownRender={(menu) => (
              <>
                {menu}
                <div style={{ padding: '8px', borderTop: '1px solid #f0f0f0' }}>
                  <small style={{ color: '#999' }}>
                    <PlusOutlined /> Type to add custom vocation or manage in Worker Types tab
                  </small>
                </div>
              </>
            )}
          />
        </Form.Item>

        <div style={{
          padding: '12px',
          background: '#f0f0f0',
          borderRadius: '4px',
          fontSize: '12px'
        }}>
          <strong>Summary:</strong> Requires {currentWorkers.required} worker{currentWorkers.required !== 1 ? 's' : ''},
          max {currentWorkers.max}. Each additional worker adds {(currentWorkers.efficiencyBonus * 100).toFixed(0)}% efficiency.
          {currentWorkers.vocations.length > 0 ? (
            <div style={{ marginTop: '4px' }}>
              Accepted vocations: {currentWorkers.vocations.map(v => (
                <Tag key={v} style={{ marginTop: '4px' }}>{v}</Tag>
              ))}
            </div>
          ) : (
            <div style={{ marginTop: '4px', color: '#999' }}>No vocations specified (any worker can work here)</div>
          )}
        </div>
      </Space>
    </>
  );
};

export default WorkerEditor;
