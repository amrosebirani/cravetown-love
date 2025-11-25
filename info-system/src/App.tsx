import { useState, useEffect } from 'react';
import { Layout, Menu, Spin } from 'antd';
import { DatabaseOutlined, AppstoreOutlined, TeamOutlined, HomeOutlined, TagsOutlined,
         BulbOutlined, UserOutlined, SmileOutlined, GiftOutlined, ThunderboltOutlined, SwapOutlined } from '@ant-design/icons';
import RecipeManager from './components/RecipeManager';
import CommodityManager from './components/CommodityManager';
import WorkerTypeManager from './components/WorkerTypeManager';
import BuildingTypeManager from './components/BuildingTypeManager';
import WorkCategoryManager from './components/WorkCategoryManager';
import DimensionManager from './components/DimensionManager';
import CharacterClassManager from './components/CharacterClassManager';
import TraitManager from './components/TraitManager';
import FulfillmentVectorManager from './components/FulfillmentVectorManager';
import EnablementRulesManager from './components/EnablementRulesManager';
import SubstitutionCalculator from './components/SubstitutionCalculator';
import './App.css';

const { Header, Content, Sider } = Layout;

type TabKey = 'recipes' | 'commodities' | 'workers' | 'buildings' | 'work-categories' |
              'dimensions' | 'character-classes' | 'traits' | 'fulfillment-vectors' | 'enablement-rules' | 'substitution-calculator';

function App() {
  const [selectedTab, setSelectedTab] = useState<TabKey>('recipes');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Initial load delay to allow Tauri to initialize
    setTimeout(() => {
      setLoading(false);
    }, 500);
  }, []);

  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header style={{
        display: 'flex',
        alignItems: 'center',
        background: '#001529',
        padding: '0 24px'
      }}>
        <div style={{
          color: 'white',
          fontSize: '20px',
          fontWeight: 'bold',
          marginRight: '24px'
        }}>
          CraveTown Information System
        </div>
      </Header>

      <Layout>
        <Sider width={200} style={{ background: '#fff' }}>
          <Menu
            mode="inline"
            selectedKeys={[selectedTab]}
            onClick={({ key }) => setSelectedTab(key as TabKey)}
            style={{ height: '100%', borderRight: 0 }}
            items={[
              {
                type: 'group',
                label: 'Production System',
                children: [
                  {
                    key: 'buildings',
                    icon: <HomeOutlined />,
                    label: 'Building Types',
                  },
                  {
                    key: 'recipes',
                    icon: <DatabaseOutlined />,
                    label: 'Building Recipes',
                  },
                  {
                    key: 'commodities',
                    icon: <AppstoreOutlined />,
                    label: 'Commodities',
                  },
                  {
                    key: 'workers',
                    icon: <TeamOutlined />,
                    label: 'Worker Types',
                  },
                  {
                    key: 'work-categories',
                    icon: <TagsOutlined />,
                    label: 'Work Categories',
                  },
                ]
              },
              {
                type: 'group',
                label: 'Craving System',
                children: [
                  {
                    key: 'dimensions',
                    icon: <BulbOutlined />,
                    label: 'Craving Dimensions',
                  },
                  {
                    key: 'character-classes',
                    icon: <UserOutlined />,
                    label: 'Character Classes',
                  },
                  {
                    key: 'traits',
                    icon: <SmileOutlined />,
                    label: 'Character Traits',
                  },
                  {
                    key: 'fulfillment-vectors',
                    icon: <GiftOutlined />,
                    label: 'Fulfillment Vectors',
                  },
                  {
                    key: 'enablement-rules',
                    icon: <ThunderboltOutlined />,
                    label: 'Enablement Rules',
                  },
                  {
                    key: 'substitution-calculator',
                    icon: <SwapOutlined />,
                    label: 'Substitution Calculator',
                  },
                ]
              },
            ]}
          />
        </Sider>

        <Layout style={{ padding: '24px' }}>
          <Content
            style={{
              padding: 24,
              margin: 0,
              minHeight: 280,
              background: '#fff',
              borderRadius: '8px',
            }}
          >
            {loading ? (
              <div style={{
                display: 'flex',
                justifyContent: 'center',
                alignItems: 'center',
                height: '400px'
              }}>
                <Spin size="large" tip="Loading..." />
              </div>
            ) : (
              <>
                {selectedTab === 'buildings' && <BuildingTypeManager />}
                {selectedTab === 'recipes' && <RecipeManager />}
                {selectedTab === 'commodities' && <CommodityManager />}
                {selectedTab === 'workers' && <WorkerTypeManager />}
                {selectedTab === 'work-categories' && <WorkCategoryManager />}
                {selectedTab === 'dimensions' && <DimensionManager />}
                {selectedTab === 'character-classes' && <CharacterClassManager />}
                {selectedTab === 'traits' && <TraitManager />}
                {selectedTab === 'fulfillment-vectors' && <FulfillmentVectorManager />}
                {selectedTab === 'enablement-rules' && <EnablementRulesManager />}
                {selectedTab === 'substitution-calculator' && <SubstitutionCalculator />}
              </>
            )}
          </Content>
        </Layout>
      </Layout>
    </Layout>
  );
}

export default App;
