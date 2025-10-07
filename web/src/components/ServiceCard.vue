<template>
  <div class="service-card" @click="$emit('select', service)">
    <button 
      class="delete-button" 
      @click.stop="$emit('delete', service)"
      title="删除服务"
    >
      X
    </button>
    
    <div class="card-header">
      <div class="ip-address">
        <div class="name-container">
          <span class="display-name">
            {{ displayName }}
            <button 
              class="edit-icon" 
              @click.stop="openEditModal"
              title="编辑名称"
            >
              ✏️
            </button>
          </span>
        </div>
        <span 
          class="status-badge" 
          :class="service.status === 'active' ? 'status-active' : 'status-inactive'"
        >
          {{ service.status === 'active' ? '活跃' : '离线' }}
        </span>
      </div>
    </div>

    <div class="time-range-selector">
      <button 
        v-for="range in timeRanges" 
        :key="range.value" 
        :class="['time-range-button', { active: selectedTimeRange === range.value }]"
        @click.stop="changeTimeRange(range.value)"
      >
        {{ range.label }}
      </button>
    </div>
    
    <div class="stats-grid">
      <div class="stat-item">
        <div class="stat-value">{{ formatBytes(getTrafficValue('up')) }}</div>
        <div class="stat-label">{{ timeRangeLabels[selectedTimeRange] }}上传</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">{{ formatBytes(getTrafficValue('down')) }}</div>
        <div class="stat-label">{{ timeRangeLabels[selectedTimeRange] }}下载</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">{{ service.inbound_count }}</div>
        <div class="stat-label">入站端口</div>
      </div>
      <div class="stat-item">
        <div class="stat-value">{{ service.client_count }}</div>
        <div class="stat-label">用户数量</div>
      </div>
    </div>

    <div class="chart-container">
      <canvas :id="'chart-' + service.id"></canvas>
    </div>
  </div>
  
  <!-- 编辑名称弹窗 -->
  <EditNameModal
    v-model:visible="showEditModal"
    :value="currentEditingValue"
    title="编辑节点名称"
    label="节点名称"
    placeholder="请输入节点名称"
    @save="saveName"
    @close="closeModal"
  />
</template>

<script setup>
import { onMounted, onUnmounted, ref, computed } from 'vue'
import { formatBytes } from '../utils/formatters'
import { servicesAPI } from '../utils/api'
import Chart from 'chart.js/auto'
import EditNameModal from './EditNameModal.vue'
import { useServicesStore } from '../stores/services'
import { watch } from 'vue'

const props = defineProps({
  service: {
    type: Object,
    required: true
  },
  trafficData: {
    type: Object,
    required: false
  }
})

defineEmits(['select', 'delete'])

// 时间范围选择相关
const selectedTimeRange = ref('today') // 默认显示今日数据
const timeRanges = [
  { label: '今日', value: 'today' },
  { label: '昨日', value: 'yesterday' },
  { label: '近3日', value: 'last3days' }
]

// 时间范围对应的标签
const timeRangeLabels = {
  'today': '今日',
  'yesterday': '昨日',
  'last3days': '近3日'
}

// 根据选择的时间范围获取对应的流量数据
const getTrafficValue = (direction) => {
  if (!props.service) return 0
  
  switch (selectedTimeRange.value) {
    case 'today':
      return direction === 'up' ? props.service.today_inbound_up || 0 : props.service.today_inbound_down || 0
    case 'yesterday':
      return direction === 'up' ? props.service.yesterday_inbound_up || 0 : props.service.yesterday_inbound_down || 0
    case 'last3days':
      return direction === 'up' ? props.service.last3days_inbound_up || 0 : props.service.last3days_inbound_down || 0
    default:
      return 0
  }
}

// 切换时间范围
const changeTimeRange = (range) => {
  selectedTimeRange.value = range
  // 防止事件冒泡触发卡片点击
  event.stopPropagation()
  // 更新图表数据
  updateChartData(range)
}

let chart = null

// 弹窗相关状态
const showEditModal = ref(false)
const currentEditingValue = ref('')

// 计算显示名称
const displayName = computed(() => {
  return props.service.custom_name || props.service.ip
})

// 打开编辑弹窗
const openEditModal = () => {
  currentEditingValue.value = props.service.custom_name || props.service.ip
  showEditModal.value = true
}

// 保存名称
const saveName = async (newName) => {
  try {
    const response = await servicesAPI.updateServiceCustomName(props.service.id, newName)
    if (response.data.success) {
      // 更新本地数据
      props.service.custom_name = newName
      // 如果当前选中的服务就是这个服务，也要更新store中的数据
      const servicesStore = useServicesStore()
      if (servicesStore.selectedService && servicesStore.selectedService.id === props.service.id) {
        servicesStore.selectedService.custom_name = newName
      }
      showEditModal.value = false
    } else {
      alert('保存失败: ' + response.data.error)
    }
  } catch (error) {
    console.error('保存名称失败:', error)
    alert('保存失败: ' + error.message)
  }
}

// 关闭弹窗
const closeModal = () => {
  showEditModal.value = false
}

// 更新图表数据
const updateChartData = (timeRange) => {
  if (!chart) return
  
  // 根据时间范围获取对应的数据
  let labels, uploadData, downloadData
  
  switch (timeRange) {
    case 'today':
      if (props.service.today_traffic_data) {
        labels = props.service.today_traffic_data.dates
        uploadData = props.service.today_traffic_data.upload_data
        downloadData = props.service.today_traffic_data.download_data
      } else if (props.trafficData) {
        labels = props.trafficData.dates
        uploadData = props.trafficData.upload_data
        downloadData = props.trafficData.download_data
      }
      break
    case 'yesterday':
      if (props.service.yesterday_traffic_data) {
        labels = props.service.yesterday_traffic_data.dates
        uploadData = props.service.yesterday_traffic_data.upload_data
        downloadData = props.service.yesterday_traffic_data.download_data
      } else if (props.trafficData) {
        labels = props.trafficData.dates
        uploadData = props.trafficData.upload_data
        downloadData = props.trafficData.download_data
      }
      break
    case 'last3days':
      if (props.service.last3days_traffic_data) {
        labels = props.service.last3days_traffic_data.dates
        uploadData = props.service.last3days_traffic_data.upload_data
        downloadData = props.service.last3days_traffic_data.download_data
      } else if (props.trafficData) {
        labels = props.trafficData.dates
        uploadData = props.trafficData.upload_data
        downloadData = props.trafficData.download_data
      }
      break
    default:
      if (props.trafficData) {
        labels = props.trafficData.dates
        uploadData = props.trafficData.upload_data
        downloadData = props.trafficData.download_data
      } else {
        labels = []
        uploadData = []
        downloadData = []
      }
  }
  
  // 确保数据存在
  if (!labels || !uploadData || !downloadData) {
    labels = []
    uploadData = []
    downloadData = []
  }
  
  // 更新图表数据
  chart.data.labels = labels
  chart.data.datasets[0].data = uploadData
  chart.data.datasets[1].data = downloadData
  chart.update()
}

const createChart = () => {
  if (!props.trafficData) return
  const ctx = document.getElementById(`chart-${props.service.id}`)
  if (ctx) {
    if (chart) {
      chart.destroy()
    }
    chart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: props.trafficData.dates,
        datasets: [
          {
            label: '上传',
            data: props.trafficData.upload_data,
            borderColor: '#74b9ff',
            backgroundColor: 'rgba(116, 185, 255, 0.1)',
            tension: 0.4,
            fill: true
          },
          {
            label: '下载',
            data: props.trafficData.download_data,
            borderColor: '#00b894',
            backgroundColor: 'rgba(0, 184, 148, 0.1)',
            tension: 0.4,
            fill: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: false
          }
        },
        scales: {
          x: {
            display: true,
            ticks: {
              color: '#2c3e50',
              font: {
                size: 10
              }
            },
            grid: {
              color: 'rgba(44, 62, 80, 0.1)'
            }
          },
          y: {
            display: true,
            ticks: {
              color: '#2c3e50',
              font: {
                size: 10
              },
              callback: function(value, index, values) {
                if (value >= 1024 * 1024 * 1024) {
                  return (value / (1024 * 1024 * 1024)).toFixed(1) + ' GB';
                } else if (value >= 1024 * 1024) {
                  return (value / (1024 * 1024)).toFixed(1) + ' MB';
                } else if (value >= 1024) {
                  return (value / 1024).toFixed(1) + ' KB';
                } else {
                  return value + ' B';
                }
              }
            },
            grid: {
              color: 'rgba(44, 62, 80, 0.1)'
            }
          }
        },
        elements: {
          point: {
            radius: 0
          }
        }
      }
    })
  }
}

watch(() => props.trafficData, () => {
  createChart()
})

onMounted(() => {
  createChart()
})

onUnmounted(() => {
  if (chart) {
    chart.destroy()
  }
})
</script>

<style scoped>
.service-card {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  transition: transform 0.2s, box-shadow 0.2s;
  position: relative;
  cursor: pointer;
  overflow: hidden;
}

.service-card:hover {
  transform: translateY(-5px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
}

/* 时间范围选择器样式 */
.time-range-selector {
  display: flex;
  justify-content: center;
  margin-bottom: 15px;
  gap: 8px;
}

.time-range-button {
  background: #f5f7fa;
  border: 1px solid #e4e7eb;
  border-radius: 15px;
  padding: 4px 10px;
  font-size: 0.8rem;
  color: #4a5568;
  cursor: pointer;
  transition: all 0.2s ease;
}

.time-range-button:hover {
  background: #edf2f7;
}

.time-range-button.active {
  background: #3498db;
  color: white;
  border-color: #3498db;
}

.name-container {
  display: flex;
  align-items: center;
  gap: 8px;
}

.display-name {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 600;
  color: #2c3e50;
}

.edit-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 14px;
  padding: 2px;
  border-radius: 3px;
  transition: all 0.2s ease;
}

.edit-icon:hover {
  background: rgba(52, 152, 219, 0.1);
}

.delete-button {
  position: absolute;
  top: 15px;
  right: 15px;
  background: #FF6B81;
  color: #fff;
  border: none;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  cursor: pointer;
  font-size: 14px;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: background 0.2s, color 0.2s, box-shadow 0.2s, transform 0.18s;
  z-index: 10;
  box-shadow: 0 2px 8px rgba(255,107,129,0.10);
}

.delete-button:hover {
  background: #FF4757;
  color: #fff;
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(255,107,129,0.18);
}
</style>