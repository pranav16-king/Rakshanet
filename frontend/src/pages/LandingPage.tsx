import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Radio,
  MapPin,
  Sparkles,
  ShieldAlert,
  ArrowRight,
  Menu,
  X,
  Compass,
  Cpu,
  Zap,
  Activity,
  CheckCircle2,
  Share2,
  ExternalLink,
  ChevronRight,
  Clock,
  PhoneCall,
  Flame,
  Globe2,
} from 'lucide-react';
import { SignalRescueLogo } from '../components/common/SignalRescueLogo';
import GatewayFlow from '@/components/ui/gateway-flow';

export const LandingPage: React.FC = () => {
  const navigate = useNavigate();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [activeTab, setActiveTab] = useState<'mesh' | 'triage' | 'map'>('mesh');

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { label: 'Home', href: '#home', active: true },
    { label: 'Features', href: '#features' },
    { label: 'How it works', href: '#how-it-works' },
    { label: 'Impact', href: '#impact' },
    { label: 'Resources', href: '#resources' },
    { label: 'About', href: '#about' },
  ];

  const handleNavClick = (href: string) => {
    setMobileMenuOpen(false);
    if (href.startsWith('#')) {
      const element = document.querySelector(href);
      if (element) {
        element.scrollIntoView({ behavior: 'smooth' });
      }
    }
  };

  return (
    <div className="min-h-screen bg-white text-slate-900 flex flex-col font-body selection:bg-amber-200 selection:text-slate-900">
      {/* ========================================================================= */}
      {/* 1. NAVIGATION BAR (Screen 1 Exact Match)                                  */}
      {/* ========================================================================= */}
      <header
        className={`sticky top-0 z-50 transition-all duration-300 ${
          scrolled
            ? 'bg-white/95 backdrop-blur-md shadow-sm border-b border-slate-200/80'
            : 'bg-white border-b border-slate-100'
        }`}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
          {/* Logo Brand with Official RakshaNet Logo & SignalRescue AI Emblem */}
          <div className="flex items-center gap-3">
            <a
              href="#home"
              onClick={(e) => {
                e.preventDefault();
                handleNavClick('#home');
              }}
              className="flex items-center gap-3 group focus:outline-none focus:ring-2 focus:ring-amber-500 rounded-lg p-1"
              aria-label="SignalRescue AI Home"
            >
              {/* Official RakshaNet Crest / SignalRescue Emblem */}
              <div className="relative flex items-center gap-2.5">
                <img
                  src="/assets/images/rakshanet_logo.png"
                  alt="Official RakshaNet Logo"
                  className="w-10 h-10 object-contain drop-shadow-sm rounded-lg"
                  onError={(e) => {
                    // Fallback to internal SVG if image fails to load
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
                <SignalRescueLogo size={36} />
              </div>
              <div className="flex flex-col">
                <span className="font-display font-black text-xl tracking-tight text-slate-900 leading-none group-hover:text-amber-600 transition-colors">
                  SignalRescue AI
                </span>
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-0.5">
                  RakshaNet Network
                </span>
              </div>
            </a>
          </div>

          {/* Desktop Center Navigation Links */}
          <nav className="hidden md:flex items-center space-x-1 lg:space-x-6" aria-label="Main Navigation">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                onClick={(e) => {
                  e.preventDefault();
                  handleNavClick(link.href);
                }}
                className={`px-3 py-2 text-sm font-semibold transition-all rounded-lg ${
                  link.active
                    ? 'text-slate-900 font-bold border-b-2 border-slate-900 rounded-b-none'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50'
                }`}
              >
                {link.label}
              </a>
            ))}
          </nav>

          {/* Right Action: Signal Yellow "Get Started" Button */}
          <div className="hidden sm:flex items-center gap-3">
            <button
              type="button"
              onClick={() => navigate('/auth/login')}
              className="h-11 px-6 rounded-full bg-[#FFC400] hover:bg-[#FFD21F] text-[#0B1220] font-bold text-sm tracking-wide shadow-sm hover:shadow-md active:scale-95 transition-all flex items-center gap-2 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-2"
              aria-label="Get Started with SignalRescue AI"
            >
              <span>Get Started</span>
              <ArrowRight size={16} className="stroke-[2.5]" />
            </button>
          </div>

          {/* Mobile Hamburger Menu Toggle */}
          <div className="flex md:hidden items-center gap-2">
            <button
              type="button"
              onClick={() => navigate('/auth/login')}
              className="h-9 px-4 rounded-full bg-[#FFC400] text-[#0B1220] font-bold text-xs shadow-sm flex items-center"
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="p-2 rounded-lg text-slate-700 hover:bg-slate-100 focus:outline-none focus:ring-2 focus:ring-amber-500 min-h-[48px] min-w-[48px] flex items-center justify-center"
              aria-label="Toggle navigation menu"
              aria-expanded={mobileMenuOpen}
            >
              {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
            </button>
          </div>
        </div>

        {/* Mobile Navigation Drawer */}
        {mobileMenuOpen && (
          <div className="md:hidden border-b border-slate-200 bg-white px-4 pt-3 pb-6 space-y-2 animate-in slide-in-from-top-2 duration-200">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                onClick={(e) => {
                  e.preventDefault();
                  handleNavClick(link.href);
                }}
                className="block px-4 py-3 rounded-xl text-base font-semibold text-slate-800 hover:bg-slate-100 hover:text-slate-900 min-h-[48px] flex items-center"
              >
                {link.label}
              </a>
            ))}
            <div className="pt-3">
              <button
                type="button"
                onClick={() => {
                  setMobileMenuOpen(false);
                  navigate('/auth/login');
                }}
                className="w-full min-h-[56px] rounded-xl bg-[#FFC400] text-[#0B1220] font-bold text-base shadow-md flex items-center justify-center gap-2"
              >
                <span>Get Started Now</span>
                <ArrowRight size={18} />
              </button>
            </div>
          </div>
        )}
      </header>

      {/* ========================================================================= */}
      {/* 2. HERO SECTION (Screen 1 Exact Match)                                    */}
      {/* ========================================================================= */}
      <section
        id="home"
        className="relative min-h-[620px] lg:min-h-[700px] flex items-center bg-[#0B1220] overflow-hidden"
      >
        {/* Background Image: Mountain Rescue Explorer */}
        <div className="absolute inset-0 z-0">
          <img
            src="/assets/images/hero_mountain_rescue.jpg"
            alt="Search and rescue explorer on mountain ridge overlooking off-grid mesh network"
            className="w-full h-full object-cover object-center scale-105 transition-transform duration-1000 ease-out"
          />
          {/* Deep Cinematic Overlay to make text perfectly readable */}
          <div className="absolute inset-0 bg-gradient-to-r from-[#0B1220]/95 via-[#0B1220]/75 to-[#0B1220]/30" />
          <div className="absolute inset-0 bg-gradient-to-t from-[#0B1220] via-transparent to-[#0B1220]/40" />

          {/* Full-bleed Disaster Mesh Gateway Particle Telemetry Stream */}
          <div className="absolute inset-0 z-0 opacity-75">
            <GatewayFlow transparent density={1.25} speed={1.1} strokeWidth={1.3} mode="dark" className="w-full h-full" />
          </div>

          {/* SVG Animated Mesh Topology Overlays */}
          <svg
            className="absolute inset-0 w-full h-full pointer-events-none opacity-60"
            xmlns="http://www.w3.org/2000/svg"
          >
            <defs>
              <radialGradient id="meshGlowCyan" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stopColor="#3CC6D0" stopOpacity="0.8" />
                <stop offset="100%" stopColor="#3CC6D0" stopOpacity="0" />
              </radialGradient>
              <radialGradient id="meshGlowYellow" cx="50%" cy="50%" r="50%">
                <stop offset="0%" stopColor="#FFD21F" stopOpacity="0.9" />
                <stop offset="100%" stopColor="#FFD21F" stopOpacity="0" />
              </radialGradient>
            </defs>

            {/* Glowing animated mesh links on mountain valley */}
            <g className="animate-pulse" style={{ animationDuration: '4s' }}>
              <line x1="65%" y1="55%" x2="78%" y2="48%" stroke="#3CC6D0" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.7" />
              <line x1="78%" y1="48%" x2="88%" y2="52%" stroke="#3CC6D0" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.7" />
              <line x1="65%" y1="55%" x2="72%" y2="68%" stroke="#FFD21F" strokeWidth="1.5" strokeDasharray="4 2" opacity="0.8" />
              <line x1="72%" y1="68%" x2="84%" y2="62%" stroke="#3CC6D0" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.6" />
              <line x1="84%" y1="62%" x2="92%" y2="70%" stroke="#FFD21F" strokeWidth="1.5" strokeDasharray="3 3" opacity="0.7" />
            </g>

            {/* Mesh Nodes with soft radial halos */}
            <circle cx="65%" cy="55%" r="14" fill="url(#meshGlowCyan)" />
            <circle cx="65%" cy="55%" r="4" fill="#3CC6D0" />

            <circle cx="78%" cy="48%" r="16" fill="url(#meshGlowYellow)" />
            <circle cx="78%" cy="48%" r="4.5" fill="#FFD21F" />

            <circle cx="88%" cy="52%" r="14" fill="url(#meshGlowCyan)" />
            <circle cx="88%" cy="52%" r="3.5" fill="#3CC6D0" />

            <circle cx="72%" cy="68%" r="18" fill="url(#meshGlowYellow)" />
            <circle cx="72%" cy="68%" r="5" fill="#FFD21F" />

            <circle cx="84%" cy="62%" r="14" fill="url(#meshGlowCyan)" />
            <circle cx="84%" cy="62%" r="4" fill="#3CC6D0" />
          </svg>
        </div>

        {/* Content Container */}
        <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 lg:py-28 w-full">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Column: Headlines & Call To Actions */}
            <div className="lg:col-span-7 xl:col-span-8 space-y-6">
              {/* Sub-pill status indicator */}
              <div className="inline-flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-slate-900/80 border border-slate-700/80 backdrop-blur-sm shadow-sm">
                <span className="relative flex h-2.5 w-2.5">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
                </span>
                <span className="text-xs font-mono font-medium text-slate-300">
                  OFF-GRID MESH PROTOCOL ACTIVE
                </span>
              </div>

              {/* Exact Display Headline from Screen 1 */}
              <h1 className="font-display font-black text-4xl sm:text-6xl xl:text-7xl text-white tracking-tight leading-[1.06] drop-shadow-md">
                Stay Connected<br />
                Save Lives<br />
                <span className="text-[#FFC400]">Anywhere.</span>
              </h1>

              {/* Subtitle matching Screen 1 */}
              <p className="text-slate-300 text-lg sm:text-xl font-normal leading-relaxed max-w-2xl">
                An offline-first disaster communication platform that connects people,
                devices and rescue teams when networks fail.
              </p>

              {/* CTA Buttons Row (56dp target) */}
              <div className="pt-4 flex flex-col sm:flex-row items-stretch sm:items-center gap-4">
                {/* Primary CTA (Signal Yellow, 56dp height) */}
                <button
                  type="button"
                  onClick={() => navigate('/auth/login')}
                  className="min-h-[56px] h-14 px-8 rounded-xl bg-[#FFC400] hover:bg-[#FFD21F] text-[#0B1220] font-black text-base shadow-xl shadow-amber-500/25 active:scale-[0.98] transition-all flex items-center justify-center gap-3 focus:outline-none focus:ring-4 focus:ring-amber-500/40"
                  aria-label="Get Started with RakshaNet SignalRescue"
                >
                  <span>Get Started</span>
                  <ArrowRight size={20} className="stroke-[2.5]" />
                </button>

                {/* Secondary CTA (Ghost Button with Border, 56dp height) */}
                <a
                  href="#features"
                  onClick={(e) => {
                    e.preventDefault();
                    handleNavClick('#features');
                  }}
                  className="min-h-[56px] h-14 px-8 rounded-xl border-2 border-white/40 hover:border-white text-white hover:bg-white/10 font-bold text-base transition-all flex items-center justify-center gap-2 focus:outline-none focus:ring-4 focus:ring-white/20"
                >
                  <span>Learn More</span>
                </a>
              </div>

              {/* Emergency Trust Badges */}
              <div className="pt-6 flex flex-wrap items-center gap-6 text-xs text-slate-400 font-medium">
                <div className="flex items-center gap-2">
                  <CheckCircle2 size={16} className="text-amber-400" />
                  <span>Zero Cellular Required</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 size={16} className="text-amber-400" />
                  <span>Peer-to-Peer Wi-Fi / BLE</span>
                </div>
                <div className="flex items-center gap-2">
                  <CheckCircle2 size={16} className="text-amber-400" />
                  <span>On-Device AI Triage</span>
                </div>
              </div>
            </div>

            {/* Right Column: Interactive Live Mesh Gateway Flow Showcase */}
            <div className="lg:col-span-5 xl:col-span-4 flex flex-col gap-4">
              <div className="relative group rounded-2xl overflow-hidden border border-slate-700/80 shadow-2xl bg-[#0B1220]/95 backdrop-blur-xl transition-all duration-300 hover:border-amber-400/50">
                {/* Header status bar */}
                <div className="px-4 py-2.5 bg-[#0E1627] border-b border-slate-800 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-2.5 h-2.5 rounded-full bg-[#FFD21F] animate-pulse"></span>
                    <span className="text-xs font-mono text-slate-200 font-bold uppercase tracking-wider">
                      Live Gateway Ingestion
                    </span>
                  </div>
                  <span className="text-[10px] font-mono font-semibold text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-500/30">
                    CLICK TO BROADCAST
                  </span>
                </div>

                {/* Gateway Flow Interactive Canvas Simulation */}
                <div className="relative h-64 sm:h-72 w-full overflow-hidden bg-black">
                  <GatewayFlow density={1.3} speed={1.1} strokeWidth={1.4} mode="dark" />
                </div>

                {/* Bottom floating badge matching Screen 1 */}
                <div className="p-3.5 bg-[#0E1627] border-t border-slate-800/80 flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="relative flex items-center justify-center w-10 h-10 rounded-xl bg-gradient-to-br from-teal-500 to-emerald-600 text-white shadow-md shadow-teal-500/30 shrink-0">
                      <Radio size={20} className="stroke-[2.2] animate-pulse" />
                      <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-amber-400 border border-white rounded-full"></span>
                    </div>
                    <div className="flex flex-col">
                      <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">
                        No Internet
                      </span>
                      <span className="text-sm font-black text-white tracking-tight leading-tight">
                        Still Connected • 18 Peers Active
                      </span>
                    </div>
                  </div>
                  <span className="text-[10px] font-mono text-amber-400 px-2 py-1 rounded bg-amber-400/10 border border-amber-400/20 font-bold">
                    DTN v2.1
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Subtle Wave Divider */}
        <div className="absolute bottom-0 left-0 right-0 h-6 bg-gradient-to-t from-slate-50 to-transparent pointer-events-none" />
      </section>

      {/* ========================================================================= */}
      {/* 3. 4 FEATURE BENEFIT CARDS (Screen 1 Exact Match)                         */}
      {/* ========================================================================= */}
      <section id="features" className="py-16 bg-slate-50 border-b border-slate-200/80">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-12">
            <h2 className="font-display font-black text-3xl sm:text-4xl text-slate-900 tracking-tight">
              Mission-Critical Capabilities
            </h2>
            <p className="text-slate-600 text-base sm:text-lg mt-3">
              Engineered from the ground up for extreme disasters when cell towers collapse and power grids blackout.
            </p>
          </div>

          {/* 4 Benefit Cards Grid matching Screen 1 */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {/* Card 1: Offline Communication (Mesh network) */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col group hover:-translate-y-1">
              <div className="w-14 h-14 rounded-2xl bg-amber-500/10 text-amber-600 flex items-center justify-center mb-5 group-hover:bg-amber-500 group-hover:text-slate-950 transition-colors">
                <Radio size={28} className="stroke-[2.2]" />
              </div>
              <h3 className="font-display font-black text-xl text-slate-900 tracking-tight">
                Offline Communication
              </h3>
              <p className="text-sm font-semibold text-amber-600 mt-1">
                Mesh network
              </p>
              <p className="text-slate-600 text-sm leading-relaxed mt-3 flex-1">
                Transmits encrypted SOS beacons and peer-to-peer chats hop-by-hop via Bluetooth Low Energy and Wi-Fi Direct.
              </p>
              <div className="mt-4 pt-4 border-t border-slate-100 flex items-center text-xs font-bold text-slate-500 group-hover:text-amber-600 transition-colors">
                <span>BLE & Wi-Fi Direct multi-hop</span>
                <ChevronRight size={14} className="ml-1" />
              </div>
            </div>

            {/* Card 2: Real-time Rescue Mapping (& Coordination) */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col group hover:-translate-y-1">
              <div className="w-14 h-14 rounded-2xl bg-sky-500/10 text-sky-600 flex items-center justify-center mb-5 group-hover:bg-sky-500 group-hover:text-white transition-colors">
                <MapPin size={28} className="stroke-[2.2]" />
              </div>
              <h3 className="font-display font-black text-xl text-slate-900 tracking-tight">
                Real-time Rescue Mapping
              </h3>
              <p className="text-sm font-semibold text-sky-600 mt-1">
                & Coordination
              </p>
              <p className="text-slate-600 text-sm leading-relaxed mt-3 flex-1">
                Offline tile caching and GPS coordinate triangulation pinpoints survivor clusters, flood lines, and rescue units.
              </p>
              <div className="mt-4 pt-4 border-t border-slate-100 flex items-center text-xs font-bold text-slate-500 group-hover:text-sky-600 transition-colors">
                <span>Vector tiles & casualty clusters</span>
                <ChevronRight size={14} className="ml-1" />
              </div>
            </div>

            {/* Card 3: AI-Powered Assistance (Life-saving Guidance) */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col group hover:-translate-y-1">
              <div className="w-14 h-14 rounded-2xl bg-teal-500/10 text-teal-600 flex items-center justify-center mb-5 group-hover:bg-teal-500 group-hover:text-white transition-colors">
                <Sparkles size={28} className="stroke-[2.2]" />
              </div>
              <h3 className="font-display font-black text-xl text-slate-900 tracking-tight">
                AI-Powered Assistance
              </h3>
              <p className="text-sm font-semibold text-teal-600 mt-1">
                Life-saving Guidance
              </p>
              <p className="text-slate-600 text-sm leading-relaxed mt-3 flex-1">
                Local on-device inference runs automated triage, medical instructions, and prioritizes urgent distress signals.
              </p>
              <div className="mt-4 pt-4 border-t border-slate-100 flex items-center text-xs font-bold text-slate-500 group-hover:text-teal-600 transition-colors">
                <span>On-device Bayesian triage</span>
                <ChevronRight size={14} className="ml-1" />
              </div>
            </div>

            {/* Card 4: Works in Disaster Zones (No Internet Needed) */}
            <div className="bg-white rounded-2xl p-6 border border-slate-200/90 shadow-sm hover:shadow-md transition-all duration-300 flex flex-col group hover:-translate-y-1">
              <div className="w-14 h-14 rounded-2xl bg-rose-500/10 text-rose-600 flex items-center justify-center mb-5 group-hover:bg-rose-500 group-hover:text-white transition-colors">
                <ShieldAlert size={28} className="stroke-[2.2]" />
              </div>
              <h3 className="font-display font-black text-xl text-slate-900 tracking-tight">
                Works in Disaster Zones
              </h3>
              <p className="text-sm font-semibold text-rose-600 mt-1">
                No Internet Needed
              </p>
              <p className="text-slate-600 text-sm leading-relaxed mt-3 flex-1">
                Fully functional in blackouts, landslides, floods, cyclones, and remote wilderness expeditions.
              </p>
              <div className="mt-4 pt-4 border-t border-slate-100 flex items-center text-xs font-bold text-slate-500 group-hover:text-rose-600 transition-colors">
                <span>Low-power battery resilience</span>
                <ChevronRight size={14} className="ml-1" />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 4. HOW IT WORKS (Tactical Disaster Flow)                                  */}
      {/* ========================================================================= */}
      <section id="how-it-works" className="py-20 bg-white border-b border-slate-200/80">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <span className="text-xs font-bold text-amber-600 uppercase tracking-widest bg-amber-50 border border-amber-200 px-3 py-1 rounded-full">
              Architecture & Lifecycle
            </span>
            <h2 className="font-display font-black text-3xl sm:text-5xl text-slate-900 tracking-tight mt-3">
              How SignalRescue AI Operates
            </h2>
            <p className="text-slate-600 text-base sm:text-lg mt-3">
              When standard telecom towers go dark, our decentralised mesh turns everyday smartphones and tactical radios into an unbreakable lifeline.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
            {/* Step 1 */}
            <div className="relative bg-slate-50 rounded-2xl p-8 border border-slate-200 flex flex-col items-start">
              <span className="text-5xl font-display font-black text-slate-200">01</span>
              <div className="w-12 h-12 rounded-xl bg-[#0B1220] text-[#FFC400] flex items-center justify-center my-4">
                <Radio size={24} />
              </div>
              <h3 className="font-display font-bold text-xl text-slate-900">
                1-Hold SOS Broadcast
              </h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                Victims or emergency responders press and hold the hi-vis SOS trigger. The device immediately broadcasts compressed distress packets with GPS, battery, and casualty triage tags.
              </p>
            </div>

            {/* Step 2 */}
            <div className="relative bg-slate-50 rounded-2xl p-8 border border-slate-200 flex flex-col items-start">
              <span className="text-5xl font-display font-black text-slate-200">02</span>
              <div className="w-12 h-12 rounded-xl bg-[#0B1220] text-[#FFC400] flex items-center justify-center my-4">
                <Share2 size={24} />
              </div>
              <h3 className="font-display font-bold text-xl text-slate-900">
                Peer Mesh Propagation
              </h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                Packets bounce silently across surrounding mobile devices within 100–300m hops. No cellular SIM or internet gateway required—the swarm automatically discovers routes.
              </p>
            </div>

            {/* Step 3 */}
            <div className="relative bg-slate-50 rounded-2xl p-8 border border-slate-200 flex flex-col items-start">
              <span className="text-5xl font-display font-black text-slate-200">03</span>
              <div className="w-12 h-12 rounded-xl bg-[#0B1220] text-[#FFC400] flex items-center justify-center my-4">
                <Compass size={24} />
              </div>
              <h3 className="font-display font-bold text-xl text-slate-900">
                Command Dispatch & Air Rescue
              </h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                When any mesh packet reaches an airborne helicopter relay, drone, or base camp satellite node, the Command Center visualises live casualty clusters and coordinates targeted extraction.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 5. IMPACT & READINESS METRICS                                             */}
      {/* ========================================================================= */}
      <section id="impact" className="py-20 bg-[#0B1220] text-white relative overflow-hidden">
        {/* Subtle grid background pattern */}
        <div
          className="absolute inset-0 opacity-10 pointer-events-none"
          style={{
            backgroundImage: 'radial-gradient(circle, #FFC400 1px, transparent 1px)',
            backgroundSize: '32px 32px',
          }}
        />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            <div className="lg:col-span-5 space-y-6">
              <span className="text-xs font-bold text-amber-400 uppercase tracking-widest bg-amber-500/10 border border-amber-500/20 px-3 py-1 rounded-full">
                Tactical Impact
              </span>
              <h2 className="font-display font-black text-3xl sm:text-5xl tracking-tight text-white leading-tight">
                Saving Hours When Minutes Matter Most
              </h2>
              <p className="text-slate-300 text-base leading-relaxed">
                Traditional disaster response suffers severe information blackout during the critical first 72 hours. RakshaNet eliminates that gap through resilient decentralized edge networking.
              </p>
              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => navigate('/auth/login')}
                  className="min-h-[48px] px-6 rounded-xl bg-[#FFC400] hover:bg-[#FFD21F] text-[#0B1220] font-bold text-sm shadow-md transition-all inline-flex items-center gap-2"
                >
                  <span>Access Incident Command Center</span>
                  <ArrowRight size={16} />
                </button>
              </div>
            </div>

            {/* Impact KPI Grid */}
            <div className="lg:col-span-7 grid grid-cols-2 gap-4 sm:gap-6">
              <div className="bg-[#162036] rounded-2xl p-6 border border-slate-700/60 flex flex-col justify-center">
                <span className="text-4xl sm:text-5xl font-display font-black text-[#FFC400]">
                  100%
                </span>
                <span className="text-base font-bold text-white mt-1">
                  Zero-Internet Uptime
                </span>
                <span className="text-xs text-slate-400 mt-1">
                  Local peer mesh functions without external backhaul
                </span>
              </div>

              <div className="bg-[#162036] rounded-2xl p-6 border border-slate-700/60 flex flex-col justify-center">
                <span className="text-4xl sm:text-5xl font-display font-black text-[#3CC6D0]">
                  &lt;250ms
                </span>
                <span className="text-base font-bold text-white mt-1">
                  Hop Latency
                </span>
                <span className="text-xs text-slate-400 mt-1">
                  Near instantaneous peer-to-peer transmission
                </span>
              </div>

              <div className="bg-[#162036] rounded-2xl p-6 border border-slate-700/60 flex flex-col justify-center">
                <span className="text-4xl sm:text-5xl font-display font-black text-emerald-400">
                  15+
                </span>
                <span className="text-base font-bold text-white mt-1">
                  Mesh Hop Reach
                </span>
                <span className="text-xs text-slate-400 mt-1">
                  Packets traverse rugged valleys across device chain
                </span>
              </div>

              <div className="bg-[#162036] rounded-2xl p-6 border border-slate-700/60 flex flex-col justify-center">
                <span className="text-4xl sm:text-5xl font-display font-black text-rose-400">
                  24/7
                </span>
                <span className="text-base font-bold text-white mt-1">
                  Autonomous Triage
                </span>
                <span className="text-xs text-slate-400 mt-1">
                  On-device AI prioritises life-threatening emergencies
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 6. RESOURCES & SPECIFICATIONS                                            */}
      {/* ========================================================================= */}
      <section id="resources" className="py-20 bg-slate-50 border-b border-slate-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center max-w-3xl mx-auto mb-16">
            <h2 className="font-display font-black text-3xl sm:text-4xl text-slate-900 tracking-tight">
              Resources & Technical Protocols
            </h2>
            <p className="text-slate-600 text-base sm:text-lg mt-3">
              Built on verified open protocols and rugged field requirements for first responders.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
              <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-800 mb-4 font-bold font-mono">
                P2P
              </div>
              <h3 className="font-bold text-lg text-slate-900">Mesh Protocol Spec</h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                Self-healing gossip routing designed for intermittent peer connections and low-power battery conservation.
              </p>
              <div className="mt-4 text-xs font-mono text-slate-500 bg-slate-50 p-2 rounded border border-slate-200">
                BLE Advertising + Wi-Fi Direct + LoRa Bridge
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
              <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-800 mb-4 font-bold font-mono">
                MAP
              </div>
              <h3 className="font-bold text-lg text-slate-900">Offline GIS Vector Tiles</h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                High-density topographical terrain maps pre-cached on device with zero dependence on external tile servers.
              </p>
              <div className="mt-4 text-xs font-mono text-slate-500 bg-slate-50 p-2 rounded border border-slate-200">
                MBTiles • Vector Overlays • GPS Fallback
              </div>
            </div>

            <div className="bg-white rounded-2xl p-6 border border-slate-200 shadow-sm">
              <div className="w-10 h-10 rounded-lg bg-slate-100 flex items-center justify-center text-slate-800 mb-4 font-bold font-mono">
                SEC
              </div>
              <h3 className="font-bold text-lg text-slate-900">Zero-Trust Cryptography</h3>
              <p className="text-slate-600 text-sm mt-2 leading-relaxed">
                End-to-end encrypted packet payloads ensure victim identities and sensitive coordinates are visible solely to verified responders.
              </p>
              <div className="mt-4 text-xs font-mono text-slate-500 bg-slate-50 p-2 rounded border border-slate-200">
                Ed25519 Signatures • ChaCha20-Poly1305
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 7. ABOUT RAKSHANET / CALL TO ACTION                                      */}
      {/* ========================================================================= */}
      <section id="about" className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="bg-gradient-to-r from-amber-50 via-amber-100/50 to-orange-50 rounded-3xl p-8 sm:p-14 border border-amber-200 shadow-sm flex flex-col lg:flex-row items-center justify-between gap-10">
            <div className="space-y-4 max-w-2xl text-center lg:text-left">
              <div className="inline-flex items-center gap-2">
                <img
                  src="/assets/images/rakshanet_logo.png"
                  alt="RakshaNet Emblem"
                  className="w-12 h-12 object-contain"
                />
                <span className="font-display font-black text-2xl text-slate-900">
                  RakshaNet • SignalRescue AI
                </span>
              </div>
              <h2 className="font-display font-black text-3xl sm:text-4xl text-slate-900 tracking-tight">
                Empowering Communities in Times of Crisis
              </h2>
              <p className="text-slate-700 text-base leading-relaxed">
                RakshaNet is dedicated to bridging the emergency communication gap. When earthquakes, floods, or landslides sever infrastructure, every citizen’s phone becomes a beacon of hope and rescue.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row gap-4 shrink-0 w-full sm:w-auto">
              <button
                type="button"
                onClick={() => navigate('/auth/login')}
                className="min-h-[56px] h-14 px-8 rounded-xl bg-[#0B1220] hover:bg-slate-800 text-white font-bold text-base shadow-lg transition-all flex items-center justify-center gap-3"
              >
                <span>Launch Command Center</span>
                <ArrowRight size={18} className="text-[#FFC400]" />
              </button>
            </div>
          </div>
        </div>
      </section>

      {/* ========================================================================= */}
      {/* 8. FOOTER                                                                 */}
      {/* ========================================================================= */}
      <footer className="bg-[#0B1220] text-slate-400 border-t border-slate-800 py-12 text-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
            {/* Col 1: Brand Info */}
            <div className="space-y-3">
              <div className="flex items-center gap-2 text-white">
                <SignalRescueLogo size={28} />
                <span className="font-display font-bold text-lg text-white">SignalRescue AI</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed">
                Offline-first disaster communication platform developed under the RakshaNet resilient infrastructure initiative.
              </p>
              <div className="flex items-center gap-2 text-xs font-mono text-emerald-400 pt-1">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                <span>System Operational • Mesh Online</span>
              </div>
            </div>

            {/* Col 2: Navigation */}
            <div>
              <h3 className="font-bold text-white text-xs uppercase tracking-wider mb-3">
                Platform
              </h3>
              <ul className="space-y-2 text-xs">
                <li><a href="#features" onClick={() => handleNavClick('#features')} className="hover:text-white transition-colors">Mesh Communication</a></li>
                <li><a href="#features" onClick={() => handleNavClick('#features')} className="hover:text-white transition-colors">Tactical Rescue Map</a></li>
                <li><a href="#features" onClick={() => handleNavClick('#features')} className="hover:text-white transition-colors">AI On-Device Triage</a></li>
                <li><a href="#how-it-works" onClick={() => handleNavClick('#how-it-works')} className="hover:text-white transition-colors">Offline Vector GIS</a></li>
              </ul>
            </div>

            {/* Col 3: Resources */}
            <div>
              <h3 className="font-bold text-white text-xs uppercase tracking-wider mb-3">
                Emergency & Docs
              </h3>
              <ul className="space-y-2 text-xs">
                <li><a href="#resources" onClick={() => handleNavClick('#resources')} className="hover:text-white transition-colors">P2P Protocol Specification</a></li>
                <li><a href="#resources" onClick={() => handleNavClick('#resources')} className="hover:text-white transition-colors">Field Responder Guidelines</a></li>
                <li><a href="#impact" onClick={() => handleNavClick('#impact')} className="hover:text-white transition-colors">Disaster Incident Records</a></li>
                <li><a href="#about" onClick={() => handleNavClick('#about')} className="hover:text-white transition-colors">Disaster Management Teams</a></li>
              </ul>
            </div>

            {/* Col 4: Incident Command Hotline */}
            <div>
              <h3 className="font-bold text-white text-xs uppercase tracking-wider mb-3">
                Command Access
              </h3>
              <p className="text-xs text-slate-400 mb-3">
                Authorised emergency personnel and tactical coordinators:
              </p>
              <button
                type="button"
                onClick={() => navigate('/auth/login')}
                className="w-full py-2.5 px-4 rounded-lg bg-[#FFC400] text-[#0B1220] font-bold text-xs hover:bg-[#FFD21F] transition-colors"
              >
                Sign In to Command Center
              </button>
            </div>
          </div>

          <div className="pt-8 border-t border-slate-800 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-400 gap-4">
            <p>© {new Date().getFullYear()} RakshaNet / SignalRescue AI. Engineered for human resilience.</p>
            <div className="flex items-center gap-6">
              <span className="text-slate-400">Strictly adheres to hi-vis beacon design system</span>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
};
