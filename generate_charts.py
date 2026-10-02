import os
import matplotlib
import matplotlib.pyplot as plt
import numpy as np

os.makedirs(r'p:\RakshaNet\docs\assets\figures', exist_ok=True)

# Styling defaults
matplotlib.rcParams['font.sans-serif'] = 'DejaVu Sans, Arial, Helvetica'
matplotlib.rcParams['axes.edgecolor'] = '#CBD5E1'
matplotlib.rcParams['axes.linewidth'] = 0.8

# FIGURE 1: Nepal-Tibet Disaster Metrics & Delays
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 4.2), dpi=200)

categories = ['Confirmed\nDead', 'Reported\nMissing', 'Injured\nSurvivors', 'Houses\nDestroyed']
counts = [1429, 5649, 6827, 8317]
colors_cas = ['#D92D20', '#E07B00', '#FFC400', '#64748B']
bars = ax1.bar(categories, counts, color=colors_cas, width=0.55, edgecolor='#1E293B', linewidth=1)
for bar in bars:
    yval = bar.get_height()
    ax1.text(bar.get_x() + bar.get_width()/2.0, yval + 150, f'{yval:,}', ha='center', va='bottom', fontsize=8.5, fontweight='bold', color='#0B1220')
ax1.set_title('Nepal-Tibet Flood Scale (Aug 2026)', fontsize=10.5, fontweight='bold', color='#0B1220', pad=12)
ax1.set_ylabel('Individuals / Structures', fontsize=9, color='#334155')
ax1.set_ylim(0, 10000)
ax1.tick_params(labelsize=8.5)

milestones = ['Border\nObliterated', 'Official Alert\nBroadcast', 'Cellular Core\nRestored', 'Village Tiru\nReached']
times = [7/60, 38/60, 9*24, 15*24] # in hours
bar_colors = ['#EF4444', '#F59E0B', '#3B82F6', '#8B5CF6']
bars2 = ax2.bar(milestones, times, color=bar_colors, width=0.55, edgecolor='#1E293B', linewidth=1)
for i, bar in enumerate(bars2):
    yval = bar.get_height()
    label = '7 mins' if i == 0 else ('38 mins' if i == 1 else ('9 days' if i == 2 else '15 days'))
    ax2.text(bar.get_x() + bar.get_width()/2.0, yval * 1.25, label, ha='center', va='bottom', fontsize=8.5, fontweight='bold', color='#0B1220')
ax2.set_title('Communication & Response Latency', fontsize=10.5, fontweight='bold', color='#0B1220', pad=12)
ax2.set_ylabel('Elapsed Time (Hours, Log Scale)', fontsize=9, color='#334155')
ax2.set_yscale('log')
ax2.set_ylim(0.05, 1000)
ax2.tick_params(labelsize=8.5)

plt.tight_layout()
fig_path1 = r'p:\RakshaNet\docs\assets\figures\fig1_nepal_disaster_metrics.png'
plt.savefig(fig_path1, bbox_inches='tight')
plt.close()
print('Generated Figure 1:', fig_path1)

# FIGURE 2: Telemetry Anomaly - Communication Gap Detection
fig, ax = plt.subplots(figsize=(8.5, 3.8), dpi=200)
times_gap = ['10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM']
devices = [500, 430, 150, 20]
bars_gap = ax.bar(times_gap, devices, color=['#0E8A94', '#22C55E', '#E07B00', '#D92D20'], width=0.48, edgecolor='#0B1220', linewidth=1)
ax.plot(times_gap, devices, color='#0B1220', marker='o', linewidth=2, linestyle='--', markersize=6)
for bar in bars_gap:
    y = bar.get_height()
    ax.text(bar.get_x() + bar.get_width()/2.0, y + 14, f'{y} Nodes', ha='center', va='bottom', fontsize=8.5, fontweight='bold', color='#0B1220')

ax.annotate('Severe Infrastructure Drop\n(198 Cell Towers Destroyed)', xy=('11:00 AM', 150), xytext=('10:20 AM', 280),
            arrowprops=dict(facecolor='#D92D20', shrink=0.08, width=1.5, headwidth=6),
            fontsize=8.5, fontweight='bold', color='#D92D20', bbox=dict(boxstyle='round,pad=0.4', fc='#FEE2E2', ec='#EF4444', lw=1))

ax.annotate('COMMUNICATION BLACK HOLE\nInstant Drone Recon Dispatch', xy=('11:30 AM', 20), xytext=('11:00 AM', 60),
            arrowprops=dict(facecolor='#D92D20', shrink=0.08, width=1.5, headwidth=6),
            fontsize=8.5, fontweight='bold', color='#991B1B', bbox=dict(boxstyle='round,pad=0.4', fc='#FEE2E2', ec='#B91C1C', lw=1))

ax.set_title('RakshaNet Telemetry Anomaly: Real-Time Communication Black Hole Detection', fontsize=11, fontweight='bold', color='#0B1220', pad=12)
ax.set_ylabel('Active P2P Mesh Handshake Heartbeats', fontsize=9, color='#334155')
ax.set_ylim(0, 600)
ax.tick_params(labelsize=8.5)
plt.tight_layout()
fig_path2 = r'p:\RakshaNet\docs\assets\figures\fig2_communication_gap_anomaly.png'
plt.savefig(fig_path2, bbox_inches='tight')
plt.close()
print('Generated Figure 2:', fig_path2)

# FIGURE 3: Competitor Capability Matrix Comparison
fig, ax = plt.subplots(figsize=(10, 4.4), dpi=200)
features_list = [
    'Offline BLE/P2P Mesh',
    'Tactile SOS Beaconing',
    'Store-and-Forward DTN',
    'Offline Vector Maps',
    'On-Device AI Triage',
    'Incident Clustering (DBSCAN)',
    'Comm-Gap Anomaly Detection',
    'Probabilistic Search Zones',
    'Resource Dispatch Optimization'
]
y_pos = np.arange(len(features_list))

scores_rn = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]
scores_cc = [1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0]
scores_ss = [1.0, 1.0, 0.5, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0]
scores_tr = [1.0, 1.0, 1.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0]

bar_height = 0.2
ax.barh(y_pos + 1.5*bar_height, scores_rn, height=bar_height, label='RakshaNet (Our Platform)', color='#FFC400', edgecolor='#0B1220', lw=1)
ax.barh(y_pos + 0.5*bar_height, scores_cc, height=bar_height, label='Crisis Connect (Production Leader)', color='#0E8A94', edgecolor='#0B1220', lw=1)
ax.barh(y_pos - 0.5*bar_height, scores_ss, height=bar_height, label='Sahayata Setu (Flutter App)', color='#3B82F6', edgecolor='#0B1220', lw=1)
ax.barh(y_pos - 1.5*bar_height, scores_tr, height=bar_height, label='Tremour (Hackathon PoC)', color='#94A3B8', edgecolor='#0B1220', lw=1)

ax.set_yticks(y_pos)
ax.set_yticklabels(features_list, fontsize=8.5, fontweight='bold', color='#0B1220')
ax.set_xticks([0, 0.5, 1.0])
ax.set_xticklabels(['Missing (0.0)', 'Partial / Stub (0.5)', 'Fully Supported (1.0)'], fontsize=8.5)
ax.set_title('Cross-Competitor Capability Matrix: Core Mesh vs Intelligence Moat', fontsize=11, fontweight='bold', color='#0B1220', pad=12)
ax.legend(loc='lower right', frameon=True, facecolor='#FFFFFF', edgecolor='#CBD5E1', fontsize=8.5)
ax.set_xlim(0, 1.35)
ax.invert_yaxis()
plt.tight_layout()
fig_path3 = r'p:\RakshaNet\docs\assets\figures\fig3_competitor_comparison_matrix.png'
plt.savefig(fig_path3, bbox_inches='tight')
plt.close()
print('Generated Figure 3:', fig_path3)

# FIGURE 4: Scenario Impact Model (Nepal Baseline)
fig, ax = plt.subplots(figsize=(8.5, 3.8), dpi=200)
adoption_rates = ['5% Adoption', '15% Adoption', '30% Adoption']
x = np.arange(len(adoption_rates))
width = 0.24

located_casualties = [326, 977, 1955]
sos_injured = [341, 1024, 2048]
resolved_missing = [38, 115, 231]

rects1 = ax.bar(x - width, located_casualties, width, label='Casualties with Last-Known Fix', color='#0E8A94', edgecolor='#0B1220', lw=1)
rects2 = ax.bar(x, sos_injured, width, label='Injured Triggering Mesh SOS', color='#FFC400', edgecolor='#0B1220', lw=1)
rects3 = ax.bar(x + width, resolved_missing, width, label='Missing Cleared by SAFE Beacons', color='#22C55E', edgecolor='#0B1220', lw=1)

for rect in rects1:
    h = rect.get_height()
    ax.text(rect.get_x() + rect.get_width()/2., h + 30, f'{h}', ha='center', va='bottom', fontsize=8, fontweight='bold')
for rect in rects2:
    h = rect.get_height()
    ax.text(rect.get_x() + rect.get_width()/2., h + 30, f'{h}', ha='center', va='bottom', fontsize=8, fontweight='bold')
for rect in rects3:
    h = rect.get_height()
    ax.text(rect.get_x() + rect.get_width()/2., h + 30, f'{h}', ha='center', va='bottom', fontsize=8, fontweight='bold')

ax.set_ylabel('Impacted Individuals', fontsize=9, color='#334155')
ax.set_title('Projected Civilian Impact by Community Adoption (Nepal 2026 Baseline)', fontsize=11, fontweight='bold', color='#0B1220', pad=12)
ax.set_xticks(x)
ax.set_xticklabels(adoption_rates, fontsize=9, fontweight='bold', color='#0B1220')
ax.legend(loc='upper left', frameon=True, facecolor='#FFFFFF', edgecolor='#CBD5E1', fontsize=8.5)
ax.set_ylim(0, 2400)
plt.tight_layout()
fig_path4 = r'p:\RakshaNet\docs\assets\figures\fig4_adoption_impact_model.png'
plt.savefig(fig_path4, bbox_inches='tight')
plt.close()
print('Generated Figure 4:', fig_path4)
