import React, { useState } from 'react';
import { 
  Trophy, Target, Book, PenTool, BarChart3, 
  CheckCircle2, Lock, Zap, ChevronDown, 
  Terminal, Shield, Package, Users, Layout, Plus, Play, Database
} from 'lucide-react';

// --- הגדרות משתמש ---
// כאן אתה מדביק את ה-ID של הגיליון שלך (הסבר למטה)
const SHEET_ID = "1CSktzpLPkN84-rtvsJHyi-lCmyfJ6G5uj3Xh9MIgwDs"; 

const App = () => {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [xp, setXp] = useState(0);

  const renderContent = () => {
    switch(activeTab) {
      case 'dashboard':
        return (
          <div className="space-y-6 animate-fadeIn">
            <header className="flex justify-between items-end">
                <div>
                    <h2 className="text-3xl font-bold text-white mb-2">לוח בקרה ראשי</h2>
                    <p className="text-gray-400">ברוך הבא למרכז העצבים, ארכיטקט.</p>
                </div>
                <div className="text-right">
                    <div className="text-4xl font-mono font-bold text-cyan-400">{xp} <span className="text-sm">XP</span></div>
                    <div className="text-xs text-gray-500 uppercase tracking-widest">Level 1</div>
                </div>
            </header>

            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="bg-gray-800/50 p-6 rounded-2xl border border-gray-700 hover:border-cyan-500/30 transition-all">
                <div className="flex items-center gap-3 mb-2 text-purple-400">
                  <Database size={20} /> <span className="font-bold">סרטונים במכונה</span>
                </div>
                <div className="text-3xl font-bold text-white">5</div>
                <div className="text-xs text-gray-500 mt-1">ממתינים לעריכה</div>
              </div>
              
              <div className="bg-gray-800/50 p-6 rounded-2xl border border-gray-700 hover:border-green-500/30 transition-all">
                <div className="flex items-center gap-3 mb-2 text-green-400">
                  <Target size={20} /> <span className="font-bold">יעד שבועי</span>
                </div>
                <div className="text-3xl font-bold text-white">3/7</div>
                <div className="text-xs text-gray-500 mt-1">סרטונים הועלו</div>
              </div>

              <div className="bg-gray-800/50 p-6 rounded-2xl border border-gray-700 hover:border-yellow-500/30 transition-all">
                <div className="flex items-center gap-3 mb-2 text-yellow-400">
                  <Zap size={20} /> <span className="font-bold">רצף (Streak)</span>
                </div>
                <div className="text-3xl font-bold text-white">2 <span className="text-sm">ימים</span></div>
                <div className="text-xs text-gray-500 mt-1">אל תשבור את השרשרת</div>
              </div>
            </div>
          </div>
        );

      case 'engine':
        return (
          <div className="h-full flex flex-col space-y-4 animate-fadeIn">
            <div className="flex justify-between items-center">
                <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                    <Database className="text-cyan-400" /> המנוע (The Engine)
                </h2>
                <div className="text-xs text-gray-400 bg-gray-800 px-3 py-1 rounded-full border border-gray-700">
                    Live Connection
                </div>
            </div>
            
            {/* The Google Sheet Embed */}
            <div className="flex-1 bg-white rounded-xl overflow-hidden border-2 border-gray-700 shadow-2xl relative">
                {SHEET_ID === "PASTE_YOUR_SHEET_ID_HERE" ? (
                    <div className="absolute inset-0 flex flex-col items-center justify-center bg-gray-900 text-center p-10">
                        <Database size={48} className="text-red-500 mb-4" />
                        <h3 className="text-xl font-bold text-white">הגיליון לא מחובר עדיין</h3>
                        <p className="text-gray-400 mt-2">
                            עליך להדביק את ה-Sheet ID שלך בקוד (שורה 10 בקובץ App.jsx).
                        </p>
                    </div>
                ) : (
                    <iframe 
                        src={`https://docs.google.com/spreadsheets/d/${SHEET_ID}/edit?rm=minimal`}
                        className="w-full h-full"
                        title="Engine DB"
                    ></iframe>
                )}
            </div>
            <p className="text-xs text-gray-500 text-center">
                הוסף רעיונות חדשים בשורות הריקות למטה. המכונה תסרוק אותם אוטומטית.
            </p>
          </div>
        );

      case 'academy':
        return <div className="text-white text-2xl flex items-center justify-center h-full text-gray-500">מודול למידה - בבנייה</div>;
        
      default:
        return null;
    }
  };

  return (
    <div className="h-screen bg-[#0B0F19] text-gray-100 font-sans flex flex-col md:flex-row overflow-hidden" dir="rtl">
      
      {/* סרגל צד */}
      <div className="w-full md:w-64 bg-[#111625] border-l border-gray-800 p-6 flex flex-col gap-6 shrink-0 z-10 shadow-xl">
        <div className="flex items-center gap-3 text-white mb-2">
          <div className="bg-cyan-600 p-2 rounded-lg shadow-[0_0_15px_rgba(8,145,178,0.5)]">
             <Terminal size={24} />
          </div>
          <div>
            <h1 className="text-lg font-bold tracking-widest leading-none">ARCHITECT</h1>
            <span className="text-[10px] text-gray-500 tracking-[0.2em]">OS v3.5</span>
          </div>
        </div>

        <nav className="space-y-2 flex-1">
          <MenuButton 
            active={activeTab === 'dashboard'} 
            onClick={() => setActiveTab('dashboard')} 
            icon={BarChart3} 
            label="מרכז בקרה" 
          />
          <MenuButton 
            active={activeTab === 'engine'} 
            onClick={() => setActiveTab('engine')} 
            icon={Database} 
            label="המנוע (Sheets)" 
            badge="LIVE"
          />
          <MenuButton 
            active={activeTab === 'academy'} 
            onClick={() => setActiveTab('academy')} 
            icon={Book} 
            label="האקדמיה" 
          />
        </nav>

        <button onClick={() => setXp(xp + 50)} className="w-full flex items-center justify-center gap-2 p-3 rounded-lg text-black bg-yellow-500 hover:bg-yellow-400 font-bold transition-all shadow-[0_0_15px_rgba(234,179,8,0.3)]">
            <Zap size={18} fill="black" /> בונוס יומי
        </button>
      </div>

      {/* תוכן ראשי */}
      <div className="flex-1 p-6 md:p-8 bg-[url('https://www.transparenttextures.com/patterns/cubes.png')] relative">
        <div className="absolute inset-0 bg-gradient-to-br from-cyan-900/10 to-transparent pointer-events-none"></div>
        {renderContent()}
      </div>

    </div>
  );
};

// רכיב עזר לכפתורי תפריט
const MenuButton = ({ active, onClick, icon: Icon, label, badge }) => (
    <button 
        onClick={onClick} 
        className={`w-full flex items-center justify-between p-3 rounded-lg transition-all group ${
            active 
            ? 'bg-cyan-950/50 text-cyan-400 border border-cyan-500/30' 
            : 'text-gray-400 hover:bg-gray-800 hover:text-white border border-transparent'
        }`}
    >
        <div className="flex items-center gap-3">
            <Icon size={20} className={active ? "text-cyan-400" : "group-hover:text-white"} />
            <span>{label}</span>
        </div>
        {badge && <span className="text-[9px] bg-red-500/20 text-red-400 px-2 py-0.5 rounded-full font-mono">{badge}</span>}
    </button>
);

export default App;