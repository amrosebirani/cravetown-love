import { useState, useEffect } from 'react';
import { Layout, Menu, Spin } from 'antd';
import { DatabaseOutlined, AppstoreOutlined, TeamOutlined, HomeOutlined, TagsOutlined,
         BulbOutlined, UserOutlined, SmileOutlined, GiftOutlined, ThunderboltOutlined, SwapOutlined, BranchesOutlined, FireOutlined, NodeIndexOutlined, ClockCircleOutlined, LinkOutlined, CalculatorOutlined } from '@ant-design/icons';
import RecipeManager from './components/RecipeManager';
import CommodityManager from './components/CommodityManager';
import CommodityCategoryManager from './components/CommodityCategoryManager';
import WorkerTypeManager from './components/WorkerTypeManager';
import BuildingTypeManager from './components/BuildingTypeManager';
import WorkCategoryManager from './components/WorkCategoryManager';
import DimensionManager from './components/DimensionManager';
import CharacterClassManager from './components/CharacterClassManager';
import TraitManager from './components/TraitManager';
import FulfillmentVectorManager from './components/FulfillmentVectorManager';
import EnablementRulesManager from './components/EnablementRulesManager';
import SubstitutionCalculator from './components/SubstitutionCalculator';
import CommodityFatigueManager from './components/CommodityFatigueManager';
import SubstitutionRulesManager from './components/SubstitutionRulesManager';
import VersionManager from './components/VersionManager';
import TimeSlotManager from './components/TimeSlotManager';
import CravingSlotManager from './components/CravingSlotManager';
import UnitsManager from './components/UnitsManager';
import { initializeVersionSystem } from './api';
import './App.css';

const { Header, Content, Sider } = Layout;

type TabKey = 'versions' | 'recipes' | 'commodities' | 'commodity-categories' | 'workers' | 'buildings' | 'work-categories' |
              'dimensions' | 'character-classes' | 'traits' | 'fulfillment-vectors' | 'enablement-rules' |
              'substitution-calculator' | 'commodity-fatigue' | 'substitution-rules' |
              'time-slots' | 'craving-slots' | 'units';

function App() {
  const [selectedTab, setSelectedTab] = useState<TabKey>('recipes');
  const [loading, setLoading] = useState(true);
  const [activeVersion, setActiveVersion] = useState<string>('base');

  useEffect(() => {
    // Initialize version system and load active version
    const init = async () => {
      try {
        const versionId = await initializeVersionSystem();
        setActiveVersion(versionId);
      } catch (error) {
        console.error('Failed to initialize version system:', error);
      } finally {
        setLoading(false);
      }
    };

    init();
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
                label: 'System',
                children: [
                  {
                    key: 'versions',
                    icon: <BranchesOutlined />,
                    label: 'Version Manager',
                  },
                ]
              },
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
                    key: 'commodity-categories',
                    icon: <TagsOutlined />,
                    label: 'Commodity Categories',
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
                label: 'Time System',
                children: [
                  {
                    key: 'time-slots',
                    icon: <ClockCircleOutlined />,
                    label: 'Time Slots',
                  },
                  {
                    key: 'units',
                    icon: <CalculatorOutlined />,
                    label: 'Units & Baselines',
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
                    key: 'craving-slots',
                    icon: <LinkOutlined />,
                    label: 'Craving-Slot Mapping',
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
                    key: 'commodity-fatigue',
                    icon: <FireOutlined />,
                    label: 'Commodity Fatigue',
                  },
                  {
                    key: 'substitution-rules',
                    icon: <NodeIndexOutlined />,
                    label: 'Substitution Rules',
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
                {selectedTab === 'versions' && <VersionManager />}
                {selectedTab === 'buildings' && <BuildingTypeManager />}
                {selectedTab === 'recipes' && <RecipeManager />}
                {selectedTab === 'commodities' && <CommodityManager />}
                {selectedTab === 'commodity-categories' && <CommodityCategoryManager />}
                {selectedTab === 'workers' && <WorkerTypeManager />}
                {selectedTab === 'work-categories' && <WorkCategoryManager />}
                {selectedTab === 'dimensions' && <DimensionManager />}
                {selectedTab === 'character-classes' && <CharacterClassManager />}
                {selectedTab === 'traits' && <TraitManager />}
                {selectedTab === 'fulfillment-vectors' && <FulfillmentVectorManager />}
                {selectedTab === 'enablement-rules' && <EnablementRulesManager />}
                {selectedTab === 'commodity-fatigue' && <CommodityFatigueManager />}
                {selectedTab === 'substitution-rules' && <SubstitutionRulesManager />}
                {selectedTab === 'substitution-calculator' && <SubstitutionCalculator />}
                {selectedTab === 'time-slots' && <TimeSlotManager />}
                {selectedTab === 'craving-slots' && <CravingSlotManager />}
                {selectedTab === 'units' && <UnitsManager />}
              </>
            )}
          </Content>
        </Layout>
      </Layout>
    </Layout>
  );
}

export default App;
