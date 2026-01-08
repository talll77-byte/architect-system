import React, { useState, useEffect } from 'react';
import { 
  Terminal, BarChart3, Book, CheckCircle2, Package, 
  Users, Shield, ChevronDown, Target, Zap, 
  PenTool, Layout, Plus, Lock, BookOpen 
} from 'lucide-react';

const initialSyllabus = [
  {
    id: 1,
    title: "שלב 1: היסודות והמיינדסט",
    desc: "לפני שבונים, מבינים את הקרקע.",
    modules: [
      { 
        name: "הפסיכולוגיה של האוטומציה", 
        done: false, 
        xp: 50,
        content: {
          summary: "ההבנה שזמן הוא המשאב היקר ביותר.",
          resources: [
            { type: "read", title: "The Almanack of Naval Ravikant", detail: "פרק: Productize Yourself" },
          ],
          action: "כתוב ביומן: משימה אחת שגוזלת זמן."
        }
      },
      { 
        name: "בחירת הנישה: Building in Public", 
        done: false, 
        xp: 50,
        content: {
          summary: "שיווק ע\"י שיתוף התהליך.",
          resources: [{ type: "person", title: "Pieter Levels", detail: "Twitter/X" }],
          action: "ציוץ ראשון בטוויטר."
        }
      }
    ]
  },
  {
    id: 2,
    title: "שלב 2: השליטה בכלים",
    desc: "לומדים את השפה של המכונות.",
    modules: [
      { name: "הנדסת פרומפטים מתקדמת", done: false, xp: 100, content: { summary: "איך לדבר למכונה.", resources: [], action: "צור פרומפט מורכב." } },
      { name: "אוטומציה לוגית: Make.com", done: false, xp: 100, content: { summary: "הדבק שמחבר את הכל.", resources: [], action: "צור תרחיש ראשון." } }
    ]
  }
];

const initialProductModules = [
  { id: 1, title: "מבוא: למה אתם כאן?", status: "ready", students: 0 },
  { id: 2, title: "הגדרת המערכת שלכם", status: "draft", students: 0 },
];

const LEVEL_THRESHOLDS = [0, 200, 500, 1000, 2000];

const SidebarItem = ({ id, icon: Icon, label, badge, activeTab, setActiveTab }) => (
  <button
    onClick={() => setActiveTab(id)}
    className={`flex items-center justify-between w-full p-3 rounded-xl transition-all mb-1 ${
      activeTab === id 
      ? 'bg-gradient-to-r from-cyan-900/50 to-transparent text-cyan-300 border-r-4 border-cyan-500' 
      : 'text-gray-400 hover:bg-gray-800 hover:text-white'
    }`}
  >
    <div className="flex items-center gap-3">
      <Icon size={20} />
      <span className="font-medium text-sm">{label}</span>
    </div>
    {badge && <span className="text-[10px] bg-cyan-600 text-white px-2 py-0.5 rounded-full">{badge}</span>}
  </button>
);

export default function App() {
  const [activeTab, setActiveTab] = useState('product_lab');
  
  const [xp, setXp] = useState(() => {
    const saved = localStorage.getItem('arch_xp_v3');
    return saved ? parseInt(saved) : 0;
  });

  const [level, setLevel] = useState(1);
  const [syllabus, setSyllabus] = useState(initialSyllabus);
  const [productModules, setProductModules] = useState(initialProductModules);
  const [expandedModule, setExpandedModule] = useState(null);
  
  useEffect(() => {
    localStorage.setItem('arch_xp_v3', xp.toString());
    const newLevel = LEVEL_THRESHOLDS.findIndex(threshold => xp < threshold);
    setLevel(newLevel === -1 ? LEVEL_THRESHOLDS.length : newLevel);
  }, [xp]);

  const handleModuleComplete = (phaseId, modIndex) => {
    const newSyllabus = [...syllabus];
    const module = newSyllabus[phaseId - 1].modules[modIndex];
    if (!module.done) {
      module.done = true;
      setXp(prev => prev + module.xp);
      setSyllabus(newSyllabus);
      
      if(confirm(`מצוין! סיימת את "${module.name}". להוסיף למוצר שלך?`)) {
          setProductModules([...productModules, {
            id: Date.now(),
            title: module.name,
            status: "draft",
            students: 0
          }]);
      }
    }
  };

  const toggleModuleExpand = (phaseId, modIndex) => {
    const uniqueId = `${phaseId}-${modIndex}`;
    setExpandedModule(expandedModule === uniqueId ? null : uniqueId);
  };

  return (
    <div className="min-h-screen bg-[#0B0F19] text-gray-100 font-sans flex flex-col md:flex-row overflow-hidden" dir="rtl">
      
      <div className="w-full md:w-64 bg-[#111625] border-l border-gray-800 p-6 flex flex-col justify-between shrink-0 shadow-2xl z-10">
        <div>
          <div className="flex items-center gap-3 mb-10 text-white">
            <div className="bg-cyan-600 p-2 rounded-lg shadow-[0_0_15px_rgba(8,145,178,0.5)]">
              <Terminal size={24} />
            </div>
            <div>
              <h1 className="text-lg font-bold tracking-wider leading-none">ARCHITECT</h1>
              <span className="text-[10px] text-gray-500 tracking-[0.2em] uppercase">Operating System</span>
            </div>
          </div>
          
          <div className="space-y-6">
            <div>
              <p className="text-xs font-bold text-gray-600 uppercase mb-3 px-3 tracking-wider">אזור הסטודנט</p>
              <SidebarItem id="dashboard" icon={BarChart3} label="מרכז בקרה" activeTab={activeTab} setActiveTab={setActiveTab} />
              <SidebarItem id="academy" icon={Book} label="האקדמיה" activeTab={activeTab} setActiveTab={setActiveTab} />
              <SidebarItem id="daily" icon={CheckCircle2} label="משימות" activeTab={activeTab} setActiveTab={setActiveTab} />
            </div>
            
            <div>
              <p className="text-xs font-bold text-gray-600 uppercase mb-3 px-3 tracking-wider">אזור היוצר</p>
              <SidebarItem id="product_lab" icon={Package} label="מעבדת המוצר" badge="NEW" activeTab={activeTab} setActiveTab={setActiveTab} />
              <SidebarItem id="community" icon={Users} label="ניהול קהילה" activeTab={activeTab} setActiveTab={setActiveTab} />
              <SidebarItem id="monetization" icon={Shield} label="מוניטיזציה" activeTab={activeTab} setActiveTab={setActiveTab} />
            </div>
          </div>
        </div>

        <div className="bg-[#1A2035] p-4 rounded-xl border border-gray-700/50 relative overflow-hidden group">
          <div className="absolute top-0 right-0 w-20 h-20 bg-cyan-500/10 blur-2xl rounded-full -mr-10 -mt-10"></div>
          <div className="flex justify-between items-center mb-2 relative z-10">
            <span className="text-xs text-gray-400 uppercase font-bold">Level {level}</span>
            <span className="text-xs text-cyan-400 font-mono">{xp} XP</span>
          </div>
          <div className="w-full bg-gray-700 h-1.5 rounded-full overflow-hidden mt-1 relative z-10">
            <div className="h-full bg-cyan-500 shadow-[0_0_10px_rgba(6,182,212,0.5)]" style={{ width: `${Math.min((xp / 2000) * 100, 100)}%` }}></div>
          </div>
        </div>
      </div>

      <div className="flex-1 p-6 md:p-10 overflow-y-auto bg-gray-900">
        
        {activeTab === 'product_lab' && (
          <div className="max-w-5xl mx-auto animate-fadeIn">
            <div className="flex justify-between items-end mb-8">
              <div>
                <h2 className="text-3xl font-bold text-white mb-2">מעבדת המוצר (The Blueprint)</h2>
                <p className="text-gray-400">כאן אנחנו הופכים את הידע שלך לנכס דיגיטלי.</p>
              </div>
              <button className="bg-cyan-600 hover:bg-cyan-500 text-white px-5 py-2.5 rounded-lg font-medium flex items-center gap-2 transition-all shadow-lg shadow-cyan-900/20">
                <Plus size={18} /> שיעור חדש
              </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              <div className="lg:col-span-2 space-y-4">
                {productModules.map((mod, idx) => (
                  <div key={mod.id} className="bg-[#151A2A] border border-gray-800 p-5 rounded-xl flex items-center justify-between group hover:border-cyan-500/30 transition-all">
                    <div className="flex items-center gap-4">
                      <div className="bg-gray-800 text-gray-400 w-8 h-8 rounded-full flex items-center justify-center font-mono text-sm border border-gray-700">
                        {idx + 1}
                      </div>
                      <div>
                        <h3 className="font-bold text-gray-200">{mod.title}</h3>
                        <div className="flex items-center gap-2 mt-1">
                          <span className={`text-[10px] uppercase tracking-wider px-2 py-0.5 rounded ${
                            mod.status === 'ready' ? 'bg-green-900/30 text-green-400' : 'bg-yellow-900/30 text-yellow-400'
                          }`}>
                            {mod.status === 'ready' ? 'מוכן לפרסום' : 'טיוטה'}
                          </span>
                        </div>
                      </div>
                    </div>
                    <div className="flex gap-2">
                      <button className="p-2 hover:bg-gray-700 rounded-lg text-gray-400 hover:text-white"><PenTool size={18} /></button>
                      <button className="p-2 hover:bg-gray-700 rounded-lg text-gray-400 hover:text-white"><Layout size={18} /></button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="bg-[#0F1320] border border-gray-800 rounded-2xl p-6 relative overflow-hidden">
                <div className="absolute top-0 right-0 p-3 opacity-5"><Target size={40} /></div>
                <h3 className="text-sm font-bold text-gray-400 uppercase tracking-wider mb-6">חווית הלקוח</h3>
                <div className="bg-white text-gray-900 rounded-[2rem] p-4 mx-auto max-w-[240px] shadow-2xl border-4 border-gray-800 relative">
                  <div className="absolute top-0 left-1/2 -translate-x-1/2 w-20 h-4 bg-gray-800 rounded-b-xl"></div>
                  <div className="mt-6 mb-4 flex justify-between items-center">
                    <div className="w-8 h-8 bg-gray-200 rounded-full"></div>
                    <div className="w-4 h-4 text-cyan-600"><Zap size={16} /></div>
                  </div>
                  <div className="space-y-3">
                    <div className="h-20 bg-gradient-to-br from-cyan-500 to-blue-600 rounded-xl p-3 text-white">
                      <div className="text-[10px] opacity-75">ההתקדמות שלך</div>
                      <div className="text-lg font-bold">12%</div>
                    </div>
                    <div className="space-y-2">
                      <div className="h-10 bg-gray-100 rounded-lg flex items-center px-2 gap-2">
                        <div className="w-4 h-4 bg-green-500 rounded-full flex items-center justify-center"><CheckCircle2 size={10} color="white" /></div>
                        <div className="h-2 w-20 bg-gray-300 rounded"></div>
                      </div>
                      <div className="h-10 bg-gray-100 rounded-lg flex items-center px-2 gap-2 opacity-50">
                        <div className="w-4 h-4 bg-gray-300 rounded-full flex items-center justify-center"><Lock size={10} /></div>
                        <div className="h-2 w-16 bg-gray-300 rounded"></div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'academy' && (
          <div className="max-w-4xl mx-auto">
            <div className="mb-6">
              <h2 className="text-2xl font-bold text-white mb-2">האקדמיה</h2>
              <p className="text-gray-400">כאן אתה לומד. כל מה שתסיים כאן, תוכל להעביר ל"מעבדת המוצר".</p>
            </div>
            
            {syllabus.map((phase) => (
              <div key={phase.id} className="bg-[#151A2A] rounded-2xl border border-gray-800 overflow-hidden mb-6">
                <div className="p-6 border-b border-gray-800 bg-gray-800/20 flex justify-between items-center">
                  <div>
                    <h3 className="text-xl font-bold text-cyan-400">שלב {phase.id}: {phase.title}</h3>
                    <p className="text-gray-400 text-sm mt-1">{phase.desc}</p>
                  </div>
                </div>
                <div className="p-2 space-y-2">
                  {phase.modules.map((module, index) => {
                    const isOpen = expandedModule === `${phase.id}-${index}`;
                    return (
                      <div key={index} className="border border-gray-700/50 rounded-xl overflow-hidden bg-[#0B0F19]/50">
                        <div 
                          onClick={() => toggleModuleExpand(phase.id, index)}
                          className={`flex items-center justify-between p-4 cursor-pointer hover:bg-gray-800/50 transition-colors ${module.done ? 'opacity-50' : ''}`}
                        >
                          <div className="flex items-center gap-3">
                            <ChevronDown size={20} className={`transition-transform ${isOpen ? 'rotate-180' : ''}`} />
                            <span className={`font-medium ${module.done ? "text-green-400 line-through" : "text-gray-200"}`}>{module.name}</span>
                          </div>
                          <span className="text-xs font-mono text-gray-500 bg-gray-900 px-2 py-1 rounded">+{module.xp} XP</span>
                        </div>
                        
                        {isOpen && (
                          <div className="p-6 bg-[#0B0F19] border-t border-gray-800">
                            <p className="text-gray-300 mb-4">{module.content.summary}</p>
                            <div className="flex gap-4 mb-6">
                              {module.content.resources.map((res, i) => (
                                <div key={i} className="text-xs bg-gray-800 px-3 py-2 rounded border border-gray-700 flex items-center gap-2">
                                  <BookOpen size={14} />
                                  {res.title}
                                </div>
                              ))}
                            </div>
                            <button
                              onClick={() => handleModuleComplete(phase.id, index)}
                              disabled={module.done}
                              className={`w-full py-3 rounded-lg font-bold transition-all flex items-center justify-center gap-2 ${
                                module.done 
                                ? 'bg-green-900/20 text-green-500 border border-green-900 cursor-default' 
                                : 'bg-cyan-600 hover:bg-cyan-500 text-white shadow-lg shadow-cyan-900/30'
                              }`}
                            >
                              {module.done ? 'הושלם (נוסף לטיוטת המוצר)' : 'סמן כהושלם והוסף למוצר שלי'}
                            </button>
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}