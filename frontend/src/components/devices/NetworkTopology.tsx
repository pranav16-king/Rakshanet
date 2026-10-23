import React, { useState } from 'react';
import { Radio, Wifi, Smartphone, Server, Zap, Shield, CheckCircle2 } from 'lucide-react';
import type { NetworkTopologyNode } from '../../types/devices';
import { StatusBadge } from '../common/StatusBadge';
import { BatteryBar } from '../common/BatteryBar';

interface NetworkTopologyProps {
  nodes: NetworkTopologyNode[];
}

export const NetworkTopology: React.FC<NetworkTopologyProps> = ({ nodes }) => {
  const [selectedNode, setSelectedNode] = useState<NetworkTopologyNode | null>(
    nodes[0] || null
  );

  return (
    <div className="space-y-4">
      {/* Topology Map Canvas & Details Split */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Visual Graph Panel */}
        <div className="lg:col-span-2 rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-4 overflow-hidden relative min-h-[460px] flex flex-col justify-between shadow-xs">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800 text-xs">
            <div className="flex items-center gap-2">
              <Radio className="w-4 h-4 text-[#8A5A00] dark:text-[#FFC400] animate-pulse" />
              <span className="font-bold text-slate-900 dark:text-slate-100">
                Ad-Hoc Mesh Topology (802.15.4 / BLE 5.3 Direct)
              </span>
            </div>
            <span className="text-slate-400 font-mono text-[11px]">
              Dynamic Routing Protocol: AODV-Mesh
            </span>
          </div>

          {/* SVG Diagram Canvas */}
          <div className="relative w-full h-[380px] bg-slate-50/50 dark:bg-slate-950/40 rounded-lg overflow-hidden border border-slate-100 dark:border-slate-800/80 my-2">
            <svg className="w-full h-full pointer-events-none" viewBox="0 0 920 440">
              <defs>
                <linearGradient id="linkGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stopColor="#FFC400" stopOpacity="0.8" />
                  <stop offset="100%" stopColor="#0E8A94" stopOpacity="0.4" />
                </linearGradient>
              </defs>

              {/* Render Connection Lines */}
              {nodes.map((node) =>
                node.connections.map((targetId) => {
                  const target = nodes.find((n) => n.id === targetId);
                  if (!target) return null;
                  return (
                    <g key={`${node.id}-${targetId}`}>
                      <line
                        x1={node.x}
                        y1={node.y}
                        x2={target.x}
                        y2={target.y}
                        stroke={node.status === 'Offline' ? '#94A3B8' : '#FFC400'}
                        strokeWidth="2"
                        strokeDasharray={node.status === 'Offline' ? '4 4' : 'none'}
                        strokeOpacity={node.status === 'Offline' ? '0.3' : '0.6'}
                      />
                    </g>
                  );
                })
              )}
            </svg>

            {/* Interactive Nodes */}
            {nodes.map((node) => {
              const isSelected = selectedNode?.id === node.id;
              const isGateway = node.type === 'gateway';
              const isRelay = node.type === 'relay';

              return (
                <div
                  key={node.id}
                  onClick={() => setSelectedNode(node)}
                  style={{
                    left: `${(node.x / 920) * 100}%`,
                    top: `${(node.y / 440) * 100}%`,
                  }}
                  className={`absolute -translate-x-1/2 -translate-y-1/2 cursor-pointer transition-transform duration-150 hover:scale-110 z-10 ${
                    isSelected ? 'scale-110' : ''
                  }`}
                >
                  <div
                    className={`flex flex-col items-center p-2 rounded-xl shadow-md border text-center ${
                      isSelected
                        ? 'ring-2 ring-[#FFC400] ring-offset-2 bg-white dark:bg-slate-900 border-[#FFC400]'
                        : isGateway
                        ? 'bg-amber-50 dark:bg-amber-950/60 border-amber-300 dark:border-amber-700'
                        : isRelay
                        ? 'bg-sky-50 dark:bg-sky-950/60 border-sky-300 dark:border-sky-700'
                        : 'bg-white dark:bg-slate-850 border-slate-200 dark:border-slate-700'
                    }`}
                  >
                    <div
                      className={`w-8 h-8 rounded-lg flex items-center justify-center mb-1 ${
                        isGateway
                          ? 'bg-[#FFC400] text-black font-black'
                          : isRelay
                          ? 'bg-sky-500 text-white'
                          : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-200'
                      }`}
                    >
                      {isGateway ? (
                        <Server className="w-4 h-4" />
                      ) : (
                        <Smartphone className="w-4 h-4" />
                      )}
                    </div>
                    <span className="font-mono text-[10px] font-bold text-slate-900 dark:text-slate-100 max-w-[85px] truncate">
                      {node.id}
                    </span>
                    <span className="text-[9px] text-slate-500 truncate max-w-[80px]">
                      {node.signalDbm} dBm
                    </span>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="flex items-center justify-between text-xs text-slate-500 pt-2 border-t border-slate-100 dark:border-slate-800">
            <div className="flex items-center gap-4">
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded bg-[#FFC400] inline-block" /> Gateway
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded bg-sky-500 inline-block" /> Relay Hops
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-3 h-3 rounded bg-slate-300 dark:bg-slate-700 inline-block" /> Edge Clients
              </span>
            </div>
            <span>Click any node to inspect radio link</span>
          </div>
        </div>

        {/* Selected Node Telemetry Inspector */}
        <div className="rounded-xl border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900 p-5 space-y-4 shadow-xs">
          {selectedNode ? (
            <>
              <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
                <div>
                  <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider block">
                    Node Inspector
                  </span>
                  <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                    {selectedNode.label}
                  </h3>
                </div>
                <StatusBadge
                  label={selectedNode.status}
                  type={
                    selectedNode.status === 'Online'
                      ? 'online'
                      : selectedNode.status === 'Relay'
                      ? 'relay'
                      : 'offline'
                  }
                  dot
                />
              </div>

              <div className="space-y-3 text-xs">
                <div className="flex justify-between items-center py-1 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500">Device Hardware ID:</span>
                  <span className="font-mono font-bold text-slate-900 dark:text-slate-100">
                    {selectedNode.id}
                  </span>
                </div>

                <div className="flex justify-between items-center py-1 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500">Node Architecture:</span>
                  <span className="font-semibold text-slate-900 dark:text-slate-100 capitalize">
                    {selectedNode.type} Node
                  </span>
                </div>

                <div className="flex justify-between items-center py-1 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500">Signal RSSI:</span>
                  <span className="font-mono font-bold text-emerald-600 dark:text-emerald-400">
                    {selectedNode.signalDbm === undefined ? 'Not reported' : `${selectedNode.signalDbm} dBm`}
                  </span>
                </div>

                <div className="flex justify-between items-center py-1 border-b border-slate-100 dark:border-slate-800">
                  <span className="text-slate-500">Hop Distance:</span>
                  <span className="font-semibold text-slate-900 dark:text-slate-100">
                    {selectedNode.hops === undefined ? 'Not reported' : selectedNode.hops === 0
                      ? '0 (Base Station)'
                      : `${selectedNode.hops} ${selectedNode.hops === 1 ? 'hop' : 'hops'}`}
                  </span>
                </div>

                <div className="py-1">
                  <span className="text-slate-500 block mb-1">Battery Level:</span>
                  {selectedNode.battery === undefined ? <span className="text-xs text-slate-500">Not reported</span> : <BatteryBar percent={selectedNode.battery} />}
                </div>

                <div className="pt-2">
                  <span className="text-slate-500 block mb-1.5 font-semibold">
                    Direct Mesh Neighbors ({selectedNode.connections.length}):
                  </span>
                  <div className="flex flex-wrap gap-1.5">
                    {selectedNode.connections.map((conn) => (
                      <span
                        key={conn}
                        className="font-mono text-[11px] px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700"
                      >
                        {conn}
                      </span>
                    ))}
                  </div>
                </div>
              </div>
            </>
          ) : (
            <div className="text-center text-xs text-slate-400 py-12">
              Select a node on the canvas to inspect telemetry
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default NetworkTopology;
