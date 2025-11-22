import { useState, useEffect } from 'react';
import { Table, Button, Space, message, Popconfirm, Modal, Input } from 'antd';
import { PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined } from '@ant-design/icons';
import type { BuildingRecipe, BuildingRecipesData } from '../types';
import { loadBuildingRecipes, saveBuildingRecipes } from '../api';
import RecipeEditor from './RecipeEditor';

const RecipeManager = () => {
  const [recipes, setRecipes] = useState<BuildingRecipe[]>([]);
  const [loading, setLoading] = useState(false);
  const [editingRecipe, setEditingRecipe] = useState<BuildingRecipe | null>(null);
  const [editorVisible, setEditorVisible] = useState(false);
  const [messageApi, contextHolder] = message.useMessage();
  const [searchText, setSearchText] = useState('');

  useEffect(() => {
    loadRecipes();
  }, []);

  // Normalize recipe to ensure buildingType is always a string
  const normalizeRecipe = (recipe: BuildingRecipe): BuildingRecipe => {
    return {
      ...recipe,
      buildingType: Array.isArray(recipe.buildingType)
        ? recipe.buildingType[0] || ''
        : recipe.buildingType
    };
  };

  const loadRecipes = async () => {
    setLoading(true);
    try {
      const data = await loadBuildingRecipes();
      // Normalize all recipes when loading
      const normalizedRecipes = data.recipes.map(normalizeRecipe);
      setRecipes(normalizedRecipes);
      messageApi.success('Recipes loaded successfully');
    } catch (error) {
      messageApi.error(`Failed to load recipes: ${error}`);
      console.error('Failed to load recipes:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveRecipes = async (updatedRecipes: BuildingRecipe[]) => {
    try {
      // Normalize all recipes before saving
      const normalizedRecipes = updatedRecipes.map(normalizeRecipe);
      const data: BuildingRecipesData = { recipes: normalizedRecipes };
      await saveBuildingRecipes(data);
      setRecipes(normalizedRecipes);
      messageApi.success('Recipes saved successfully');
    } catch (error) {
      messageApi.error(`Failed to save recipes: ${error}`);
      console.error('Failed to save recipes:', error);
    }
  };

  const handleAddRecipe = () => {
    const newRecipe: BuildingRecipe = {
      buildingType: 'new_building',
      name: 'New Building',
      recipeName: 'Default Recipe',
      category: 'Production',
      productionTime: 60,
      inputs: {},
      outputs: {},
      workers: {
        required: 1,
        max: 3,
        vocations: [],
        efficiencyBonus: 0.1
      },
      notes: ''
    };
    setEditingRecipe(newRecipe);
    setEditorVisible(true);
  };

  const handleEditRecipe = (recipe: BuildingRecipe) => {
    setEditingRecipe({ ...recipe });
    setEditorVisible(true);
  };

  const handleSaveRecipe = (recipe: BuildingRecipe) => {
    const isNew = !recipes.find(r =>
      r.buildingType === editingRecipe?.buildingType &&
      r.recipeName === editingRecipe?.recipeName
    );

    let updatedRecipes: BuildingRecipe[];
    if (isNew) {
      updatedRecipes = [...recipes, recipe];
    } else {
      updatedRecipes = recipes.map(r =>
        (r.buildingType === editingRecipe?.buildingType &&
         r.recipeName === editingRecipe?.recipeName) ? recipe : r
      );
    }

    saveRecipes(updatedRecipes);
    setEditorVisible(false);
    setEditingRecipe(null);
  };

  const handleDeleteRecipe = async (buildingType: string, recipeName: string) => {
    const updatedRecipes = recipes.filter(r =>
      !(r.buildingType === buildingType && r.recipeName === recipeName)
    );
    await saveRecipes(updatedRecipes);
  };

  const columns = [
    {
      title: 'Building Type',
      dataIndex: 'buildingType',
      key: 'buildingType',
      width: 120,
    },
    {
      title: 'Building Name',
      dataIndex: 'name',
      key: 'name',
      width: 140,
    },
    {
      title: 'Recipe Name',
      dataIndex: 'recipeName',
      key: 'recipeName',
      width: 140,
    },
    {
      title: 'Category',
      dataIndex: 'category',
      key: 'category',
      width: 110,
    },
    {
      title: 'Production Time (s)',
      dataIndex: 'productionTime',
      key: 'productionTime',
      width: 120,
      align: 'center' as const,
    },
    {
      title: 'Inputs',
      key: 'inputs',
      width: 200,
      render: (_: unknown, record: BuildingRecipe) => {
        const inputs = Object.entries(record.inputs);
        if (inputs.length === 0) return <span style={{ color: '#999' }}>None</span>;
        return (
          <div>
            {inputs.map(([name, qty]) => (
              <div key={name}>{name}: {qty}</div>
            ))}
          </div>
        );
      },
    },
    {
      title: 'Outputs',
      key: 'outputs',
      width: 200,
      render: (_: unknown, record: BuildingRecipe) => {
        const outputs = Object.entries(record.outputs);
        if (outputs.length === 0) return <span style={{ color: '#999' }}>None</span>;
        return (
          <div>
            {outputs.map(([name, qty]) => (
              <div key={name}>{name}: {qty}</div>
            ))}
          </div>
        );
      },
    },
    {
      title: 'Workers',
      key: 'workers',
      width: 150,
      render: (_: unknown, record: BuildingRecipe) => (
        <div>
          <div>Required: {record.workers.required}</div>
          <div>Max: {record.workers.max}</div>
        </div>
      ),
    },
    {
      title: 'Actions',
      key: 'actions',
      width: 120,
      fixed: 'right' as const,
      render: (_: unknown, record: BuildingRecipe) => (
        <Space>
          <Button
            type="link"
            icon={<EditOutlined />}
            onClick={() => handleEditRecipe(record)}
          />
          <Popconfirm
            title="Delete this recipe?"
            description="This action cannot be undone."
            onConfirm={() => handleDeleteRecipe(record.buildingType, record.recipeName)}
            okText="Yes"
            cancelText="No"
          >
            <Button
              type="link"
              danger
              icon={<DeleteOutlined />}
            />
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // Filter recipes based on search text
  const filteredRecipes = recipes.filter(recipe => {
    const searchLower = searchText.toLowerCase();

    // Normalize buildingType to string (handle array from tags mode)
    const buildingType = Array.isArray(recipe.buildingType)
      ? recipe.buildingType[0]
      : recipe.buildingType;

    return (
      (buildingType && buildingType.toLowerCase().includes(searchLower)) ||
      recipe.name.toLowerCase().includes(searchLower) ||
      recipe.recipeName.toLowerCase().includes(searchLower) ||
      Object.keys(recipe.inputs).some(input => input.toLowerCase().includes(searchLower)) ||
      Object.keys(recipe.outputs).some(output => output.toLowerCase().includes(searchLower)) ||
      recipe.notes.toLowerCase().includes(searchLower) ||
      recipe.workers.vocations.some(vocation => vocation.toLowerCase().includes(searchLower))
    );
  });

  return (
    <>
      {contextHolder}
      <div>
        <div style={{ marginBottom: 16, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ margin: 0 }}>Building Recipes</h2>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAddRecipe}
          >
            Add Recipe
          </Button>
        </div>

        <Input
          placeholder="Search recipes by building name, recipe name, type, inputs, outputs, or vocations..."
          prefix={<SearchOutlined />}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          style={{ marginBottom: 16 }}
          allowClear
        />

        <Table
          columns={columns}
          dataSource={filteredRecipes}
          rowKey={(record) => `${record.buildingType}-${record.recipeName}`}
          loading={loading}
          scroll={{ x: 1300 }}
          pagination={{
            pageSize: 10,
            showSizeChanger: true,
            showTotal: (total) => `Total ${total} recipes${searchText ? ` (filtered from ${recipes.length})` : ''}`,
          }}
        />

        <Modal
          title={editingRecipe && recipes.find(r => r.buildingType === editingRecipe.buildingType) ? 'Edit Recipe' : 'Add Recipe'}
          open={editorVisible}
          onCancel={() => {
            setEditorVisible(false);
            setEditingRecipe(null);
          }}
          footer={null}
          width={800}
          destroyOnClose
        >
          {editingRecipe && (
            <RecipeEditor
              recipe={editingRecipe}
              onSave={handleSaveRecipe}
              onCancel={() => {
                setEditorVisible(false);
                setEditingRecipe(null);
              }}
            />
          )}
        </Modal>
      </div>
    </>
  );
};

export default RecipeManager;
