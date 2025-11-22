import { useState, useEffect } from 'react';
import { Form, Input, InputNumber, Button, Divider, Select } from 'antd';
import type { BuildingRecipe } from '../types';
import InputOutputEditor from './InputOutputEditor';
import WorkerEditor from './WorkerEditor';
import { loadBuildingTypes } from '../api';

const BUILDING_CATEGORIES = ['Production', 'Consumable', 'Merchandise', 'Luxury', 'Mint'];

interface RecipeEditorProps {
  recipe: BuildingRecipe;
  onSave: (recipe: BuildingRecipe) => void;
  onCancel: () => void;
}

const RecipeEditor = ({ recipe, onSave, onCancel }: RecipeEditorProps) => {
  const [form] = Form.useForm();
  const [editedRecipe, setEditedRecipe] = useState<BuildingRecipe>(recipe);
  const [buildingTypeOptions, setBuildingTypeOptions] = useState<Array<{ value: string; label: string }>>([]);

  useEffect(() => {
    loadBuildingTypeOptions();
  }, []);

  const loadBuildingTypeOptions = async () => {
    try {
      const data = await loadBuildingTypes();
      const options = data.buildingTypes.map(bt => ({
        value: bt.id,
        label: `${bt.name} (${bt.id})`
      }));
      setBuildingTypeOptions(options);
    } catch (error) {
      console.error('Failed to load building types:', error);
      // Silently fail, user can still type custom building type
    }
  };

  const handleSubmit = () => {
    form.validateFields().then(() => {
      // Ensure buildingType is a string (not array from tags mode)
      const normalizedRecipe = {
        ...editedRecipe,
        buildingType: Array.isArray(editedRecipe.buildingType)
          ? editedRecipe.buildingType[0]
          : editedRecipe.buildingType
      };
      onSave(normalizedRecipe);
    });
  };

  const updateRecipe = (updates: Partial<BuildingRecipe>) => {
    setEditedRecipe({ ...editedRecipe, ...updates });
  };

  return (
    <Form
      form={form}
      layout="vertical"
      initialValues={recipe}
      onFinish={handleSubmit}
    >
      <Form.Item
        label="Building Type"
        name="buildingType"
        rules={[{ required: true, message: 'Building type is required' }]}
        tooltip="Select building type from Building Types tab or type custom ID"
      >
        <Select
          showSearch
          value={editedRecipe.buildingType}
          onChange={(value) => {
            // Handle both array (from tags mode) and string
            const buildingType = Array.isArray(value) ? value[0] : value;
            updateRecipe({ buildingType });
          }}
          placeholder="Select or type building type ID"
          options={buildingTypeOptions}
          mode="tags"
          maxCount={1}
          dropdownRender={(menu) => (
            <>
              {menu}
              <div style={{ padding: '8px', borderTop: '1px solid #f0f0f0' }}>
                <small style={{ color: '#999' }}>
                  Type to add custom building type or manage in Building Types tab
                </small>
              </div>
            </>
          )}
        />
      </Form.Item>

      <Form.Item
        label="Building Name"
        name="name"
        rules={[{ required: true, message: 'Building name is required' }]}
        tooltip="Display name for the building (e.g., 'Farm', 'Bakery')"
      >
        <Input
          value={editedRecipe.name}
          onChange={(e) => updateRecipe({ name: e.target.value })}
        />
      </Form.Item>

      <Form.Item
        label="Recipe Name"
        name="recipeName"
        rules={[{ required: true, message: 'Recipe name is required' }]}
        tooltip="Name for this specific recipe (e.g., 'Wheat Production', 'Rye Production')"
      >
        <Input
          value={editedRecipe.recipeName}
          onChange={(e) => updateRecipe({ recipeName: e.target.value })}
        />
      </Form.Item>

      <Form.Item
        label="Category"
        name="category"
        rules={[{ required: true, message: 'Category is required' }]}
        tooltip="Building type category (Production, Consumable, Merchandise, Luxury, Mint)"
      >
        <Select
          value={editedRecipe.category}
          onChange={(value) => updateRecipe({ category: value })}
        >
          {BUILDING_CATEGORIES.map(cat => (
            <Select.Option key={cat} value={cat}>{cat}</Select.Option>
          ))}
        </Select>
      </Form.Item>

      <Form.Item
        label="Production Time (seconds)"
        name="productionTime"
        rules={[{ required: true, message: 'Production time is required' }]}
      >
        <InputNumber
          min={1}
          style={{ width: '100%' }}
          value={editedRecipe.productionTime}
          onChange={(value) => updateRecipe({ productionTime: value || 60 })}
        />
      </Form.Item>

      <Divider>Inputs & Outputs</Divider>

      <Form.Item label="Inputs">
        <InputOutputEditor
          value={editedRecipe.inputs}
          onChange={(inputs) => updateRecipe({ inputs })}
          type="inputs"
        />
      </Form.Item>

      <Form.Item label="Outputs">
        <InputOutputEditor
          value={editedRecipe.outputs}
          onChange={(outputs) => updateRecipe({ outputs })}
          type="outputs"
        />
      </Form.Item>

      <Divider>Worker Requirements</Divider>

      <WorkerEditor
        workers={editedRecipe.workers}
        onChange={(workers) => updateRecipe({ workers })}
      />

      <Divider>Additional Information (Optional)</Divider>

      <Form.Item
        label="Acceleration Clause"
        name="accelerationClause"
        tooltip="How additional workers affect production speed"
      >
        <Input.TextArea
          rows={2}
          value={editedRecipe.accelerationClause || ''}
          onChange={(e) => updateRecipe({ accelerationClause: e.target.value })}
          placeholder="e.g., 1 Additional Worker can reduce production time by 20%"
        />
      </Form.Item>

      <Form.Item
        label="Additional Logic"
        name="additionalLogic"
        tooltip="Special requirements or logic for this building"
      >
        <Input.TextArea
          rows={2}
          value={editedRecipe.additionalLogic || ''}
          onChange={(e) => updateRecipe({ additionalLogic: e.target.value })}
          placeholder="e.g., Needs proximity near Trees"
        />
      </Form.Item>

      <Form.Item label="Notes" name="notes">
        <Input.TextArea
          rows={3}
          value={editedRecipe.notes}
          onChange={(e) => updateRecipe({ notes: e.target.value })}
        />
      </Form.Item>

      <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '8px', marginTop: '24px' }}>
        <Button onClick={onCancel}>
          Cancel
        </Button>
        <Button type="primary" onClick={handleSubmit}>
          Save
        </Button>
      </div>
    </Form>
  );
};

export default RecipeEditor;
