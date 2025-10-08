<template>
  <div class="container">
    <button class="back-button" @click="backToHome">
      ← 返回主页
    </button>

    <div class="header">
      <h1>
        {{ selectedService?.custom_name || selectedService?.ip }}
        <button 
          class="edit-icon" 
          @click="startEditServiceName"
          title="编辑节点名称"
        >
          ✏️
        </button>
      </h1>
    </div>

    <div class="detail-container" v-if="selectedService">
      <div class="detail-header">
        <div class="detail-title">服务信息</div>
        <button class="refresh-button" @click="refreshDetail" :disabled="isRefreshing">
          {{ isRefreshing ? '刷新中...' : '刷新数据' }}
        </button>
      </div>


      <div class="chart-section">
        <div class="chart-header">
          <div class="section-title">流量趋势</div>
          <div class="time-range-selector">
            <button 
              class="time-range-button" 
              :class="{ active: selectedTimeRange === 'today' }"
              @click="changeTimeRange('today')"
            >
              今日
            </button>
            <button 
              class="time-range-button" 
              :class="{ active: selectedTimeRange === 'yesterday' }"
              @click="changeTimeRange('yesterday')"
            >
              昨日
            </button>
            <button 
              class="time-range-button" 
              :class="{ active: selectedTimeRange === 'last3days' }"
              @click="changeTimeRange('last3days')"
            >
              近3日
            </button>
            <button 
              class="time-range-button" 
              :class="{ active: selectedTimeRange === 'weekly' }"
              @click="changeTimeRange('weekly')"
            >
              7天
            </button>
            <button 
              class="time-range-button" 
              :class="{ active: selectedTimeRange === 'monthly' }"
              @click="changeTimeRange('monthly')"
            >
              30天
            </button>
          </div>
        </div>
        <div class="chart-container">
          <canvas id="detail-chart"></canvas>
        </div>
      </div>
      
      <!-- 24小时流量用量展示 -->
      <div class="chart-section" v-if="selectedTimeRange === 'today' || selectedTimeRange === 'yesterday'">
        <div class="chart-header">
          <div class="section-title">24小时流量分布</div>
        </div>
        <div class="hourly-traffic-container">
          <div class="hourly-chart-container">
            <canvas id="hourly-chart"></canvas>
          </div>
        </div>
      </div>
      
      <!-- 历史数据回顾 -->
      <div class="chart-section">
        <div class="chart-header">
          <div class="section-title">历史流量趋势</div>
          <div class="history-controls">
            <el-date-picker
              v-model="historyDateRange"
              type="daterange"
              range-separator="至"
              start-placeholder="开始日期"
              end-placeholder="结束日期"
              format="YYYY-MM-DD"
              value-format="YYYY-MM-DD"
              :clearable="false"
              :editable="false"
              @change="loadHistoryData"
            />
            <el-button type="primary" size="small" @click="loadHistoryData">查询</el-button>
          </div>
        </div>
        <div class="history-chart-container">
          <canvas id="history-chart"></canvas>
        </div>
      </div>

      <div class="traffic-tables">
        <div class="traffic-table">
          <div class="table-title">入站{{ timeRangeLabels[selectedTimeRange] }}流量</div>
          <div 
            v-for="inbound in sortedInbounds" 
            :key="inbound.id" 
            class="table-row"
            @click="viewPortDetail(selectedService.id, inbound.tag)"
            style="cursor:pointer;"
          >
            <div class="table-label-container">
              <div 
                class="table-label"
              >
                <span class="display-name">
                  {{ inbound.custom_name || inbound.tag }}
                  <button 
                    class="edit-icon" 
                    @click.stop="startEditInbound(inbound)"
                    title="编辑入站名称"
                  >
                    ✏️
                  </button>
                </span>
              </div>
            </div>
            <div class="table-value">
              <span class="upload-traffic">
                <span class="traffic-icon">↑</span>
                {{ formatBytes(inbound.up) }}
              </span>
              <span class="download-traffic">
                <span class="traffic-icon">↓</span>
                {{ formatBytes(inbound.down) }}
              </span>
            </div>
          </div>
        </div>

        <div class="traffic-table">
          <div class="table-title">用户今日流量</div>
          <div 
            v-for="client in sortedClients" 
            :key="client.id" 
            class="table-row"
            @click="viewUserDetail(selectedService.id, client.email)"
            style="cursor:pointer;"
          >
            <div class="table-label-container">
              <div 
                class="table-label"
              >
                <span class="display-name">
                  {{ client.custom_name || client.email }}
                  <button 
                    class="edit-icon" 
                    @click.stop="startEditClient(client)"
                    title="编辑用户名称"
                  >
                    ✏️
                  </button>
                </span>
              </div>
            </div>
            <div class="table-value">
              <span class="upload-traffic">
                <span class="traffic-icon">↑</span>
                {{ formatBytes(client.up) }}
              </span>
              <span class="download-traffic">
                <span class="traffic-icon">↓</span>
                {{ formatBytes(client.down) }}
              </span>
            </div>
          </div>
        </div>
      </div>

      
      
    </div>
  </div>
  
  <!-- 编辑节点名称弹窗 -->
  <EditNameModal
    v-model:visible="showServiceModal"
    :value="currentEditingValue"
    title="编辑节点名称"
    label="节点名称"
    placeholder="请输入节点名称"
    @save="saveServiceName"
    @close="closeServiceModal"
  />
  
  <!-- 编辑入站名称弹窗 -->
  <EditNameModal
    v-model:visible="showInboundModal"
    :value="currentEditingValue"
    title="编辑入站名称"
    label="入站名称"
    placeholder="请输入入站名称"
    @save="saveInboundName"
    @close="closeInboundModal"
  />
  
  <!-- 编辑用户名称弹窗 -->
  <EditNameModal
    v-model:visible="showClientModal"
    :value="currentEditingValue"
    title="编辑用户名称"
    label="用户名称"
    placeholder="请输入用户名称"
    @save="saveClientName"
    @close="closeClientModal"
  />
</template>

<script setup>
import { onMounted, onUnmounted, computed, ref, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useServicesStore } from '../stores/services'
import { formatBytes as rawFormatBytes } from '../utils/formatters'
import { servicesAPI } from '../utils/api'
import Chart from 'chart.js/auto'
import EditNameModal from '../components/EditNameModal.vue'

const route = useRoute()
const router = useRouter()
const servicesStore = useServicesStore()

const selectedService = computed(() => servicesStore.selectedService)

let detailChart = null
let hourlyChart = null
let historyChart = null
let refreshInterval = null
const isRefreshing = ref(false)
const chartPeriod = ref('7d') // 图表周期：7d 或 30d
const selectedTimeRange = ref('today')
const timeRangeLabels = {
  'today': '今日',
  'yesterday': '昨日',
  'last3days': '近3日',
  'weekly': '7天',
  'monthly': '30天'
}

// 历史数据相关
// 设置默认历史日期范围为最近30天
const historyDateRange = ref([
  dayjs().subtract(30, 'day').format('YYYY-MM-DD'),
  dayjs().format('YYYY-MM-DD')
])
const historyData = ref(null)
const isLoadingHistory = ref(false)

// 弹窗相关状态
const showServiceModal = ref(false)
const showInboundModal = ref(false)
const showClientModal = ref(false)
const currentEditingInbound = ref(null)
const currentEditingClient = ref(null)
const currentEditingValue = ref('')

// 编辑相关函数
const startEditInbound = (inbound) => {
  currentEditingInbound.value = inbound
  currentEditingValue.value = inbound.custom_name || inbound.tag
  showInboundModal.value = true
}

const saveInboundName = async (newName) => {
  try {
    const response = await servicesAPI.updateInboundCustomName(
      selectedService.value.id, 
      currentEditingInbound.value.tag, 
      newName
    )
    if (response.data.success) {
      currentEditingInbound.value.custom_name = newName
      // 同时更新selectedService中对应的端口数据
      const inboundInService = selectedService.value.inbound_traffics.find(
        i => i.tag === currentEditingInbound.value.tag
      )
      if (inboundInService) {
        inboundInService.custom_name = newName
      }
      showInboundModal.value = false
    } else {
      alert('保存失败: ' + response.data.error)
    }
  } catch (error) {
    console.error('保存入站失败:', error)
    alert('保存失败: ' + error.message)
  }
}

const closeInboundModal = () => {
  showInboundModal.value = false
  currentEditingInbound.value = null
}

const startEditClient = (client) => {
  currentEditingClient.value = client
  currentEditingValue.value = client.custom_name || client.email
  showClientModal.value = true
}

const saveClientName = async (newName) => {
  try {
    const response = await servicesAPI.updateClientCustomName(
      selectedService.value.id, 
      currentEditingClient.value.email, 
      newName
    )
    if (response.data.success) {
      currentEditingClient.value.custom_name = newName
      // 同时更新selectedService中对应的用户数据
      const clientInService = selectedService.value.client_traffics.find(
        c => c.email === currentEditingClient.value.email
      )
      if (clientInService) {
        clientInService.custom_name = newName
      }
      showClientModal.value = false
    } else {
      alert('保存失败: ' + response.data.error)
    }
  } catch (error) {
    console.error('保存用户名称失败:', error)
    alert('保存失败: ' + error.message)
  }
}

const closeClientModal = () => {
  showClientModal.value = false
  currentEditingClient.value = null
}

// 编辑节点名称
const startEditServiceName = () => {
  currentEditingValue.value = selectedService.value?.custom_name || selectedService.value?.ip
  showServiceModal.value = true
}

const saveServiceName = async (newName) => {
  try {
    const response = await servicesAPI.updateServiceCustomName(selectedService.value.id, newName)
    if (response.data.success) {
      selectedService.value.custom_name = newName
      showServiceModal.value = false
    } else {
      alert('保存失败: ' + response.data.error)
    }
  } catch (error) {
    console.error('保存节点名称失败:', error)
    alert('保存失败: ' + error.message)
  }
}

const closeServiceModal = () => {
  showServiceModal.value = false
}

// 切换图表周期
const switchChartPeriod = async (period) => {
  if (chartPeriod.value === period) return
  
  chartPeriod.value = period
  await createDetailChart()
}

// 切换时间范围
const changeTimeRange = async (range) => {
  if (selectedTimeRange.value === range) return
  
  selectedTimeRange.value = range
  await refreshDetail()
  
  // 如果是今日或昨日，创建小时流量图表
  if (range === 'today' || range === 'yesterday') {
    setTimeout(() => {
      createHourlyChart()
    }, 500)
  }
}

// 创建24小时流量图表
const createHourlyChart = () => {
  try {
    const ctx = document.getElementById('hourly-chart')
    if (!ctx) {
      console.warn('hourly-chart canvas element not found')
      return
    }
    
    if (!selectedService.value) {
      console.warn('No selected service available for hourly chart')
      return
    }
    
    // 获取小时数据
    let hourlyData = []
    if (selectedTimeRange.value === 'today' && selectedService.value.today_hourly_data) {
      hourlyData = selectedService.value.today_hourly_data
    } else if (selectedTimeRange.value === 'yesterday' && selectedService.value.yesterday_hourly_data) {
      hourlyData = selectedService.value.yesterday_hourly_data
    } else {
      // 模拟数据用于展示
      hourlyData = Array.from({length: 24}, (_, i) => ({
        hour: i,
        up: Math.floor(Math.random() * 100000000),
        down: Math.floor(Math.random() * 500000000)
      }))
    }
    
    // 准备图表数据
    const labels = hourlyData.map(item => `${item.hour}:00`)
    const uploadData = hourlyData.map(item => item.up)
    const downloadData = hourlyData.map(item => item.down)
    
    // 销毁现有图表
    if (hourlyChart) {
      hourlyChart.destroy()
      hourlyChart = null
    }
    
    hourlyChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: '上传',
            data: uploadData,
            backgroundColor: 'rgba(116, 185, 255, 0.7)',
            borderColor: '#74b9ff',
            borderWidth: 1
          },
          {
            label: '下载',
            data: downloadData,
            backgroundColor: 'rgba(0, 184, 148, 0.7)',
            borderColor: '#00b894',
            borderWidth: 1
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            display: true,
            position: 'top'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return context.dataset.label + ': ' + formatBytes(context.parsed.y)
              }
            }
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: '时间'
            }
          },
          y: {
            title: {
              display: true,
              text: '流量'
            },
            ticks: {
              callback: function(value) {
                return formatBytes(value)
              }
            }
          }
        }
      }
    })
  } catch (error) {
    console.error('创建小时流量图表失败:', error)
  }
}

const createDetailChart = async () => {
  try {
    // 根据选择的时间范围获取对应的数据
    const ctx = document.getElementById('detail-chart')
    
    if (!ctx) {
      console.warn('detail-chart canvas element not found')
      return
    }
    
    if (!selectedService.value) {
      console.warn('No selected service available')
      return
    }
    
    // 销毁现有图表
    if (detailChart) {
      detailChart.destroy()
      detailChart = null
    }
    
    // 根据选择的时间范围获取对应的数据
    let data = {}
    
    switch (selectedTimeRange.value) {
      case 'today':
        data = selectedService.value.today_traffic_data || {}
        break
      case 'yesterday':
        data = selectedService.value.yesterday_traffic_data || {}
        break
      case 'last3days':
        data = selectedService.value.last3days_traffic_data || {}
        break
      case 'weekly':
        data = selectedService.value.weekly_traffic_data || {}
        break
      case 'monthly':
        data = selectedService.value.monthly_traffic_data || {}
        break
      default:
        data = selectedService.value.today_traffic_data || {}
    }
    
    // 确保数据存在，如果不存在则使用空数组或模拟数据
    let labels = data.dates || []
    let uploadData = data.upload_data || []
    let downloadData = data.download_data || []
    
    // 如果没有数据，创建一些示例数据用于展示
    if (labels.length === 0) {
      const now = new Date()
      labels = []
      uploadData = []
      downloadData = []
      
      for (let i = 6; i >= 0; i--) {
        const date = new Date(now)
        date.setDate(date.getDate() - i)
        labels.push(date.toLocaleDateString())
        uploadData.push(Math.floor(Math.random() * 1000000000))
        downloadData.push(Math.floor(Math.random() * 5000000000))
      }
    }
      
      detailChart = new Chart(ctx, {
          type: 'line',
          data: {
            labels: labels,
            datasets: [
              {
                label: '上传',
                data: uploadData,
                borderColor: '#74b9ff',
                backgroundColor: 'rgba(116, 185, 255, 0.1)',
                tension: 0.4,
                fill: true
              },
              {
                 label: '下载',
                 data: downloadData,
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
                display: true,
                position: 'top',
                labels: {
                  color: '#2c3e50',
                  font: {
                    size: 14,
                    weight: 'bold'
                  }
                }
              }
            },
            scales: {
              x: {
                display: true,
                title: {
                  display: true,
                  text: '日期',
                  color: '#2c3e50',
                  font: {
                    size: 14,
                    weight: 'bold'
                  }
                },
                ticks: {
                  color: '#2c3e50',
                  font: {
                    size: 12
                  }
                },
                grid: {
                  color: 'rgba(44, 62, 80, 0.1)'
                }
              },
              y: {
                display: true,
                title: {
                  display: true,
                  text: '流量',
                  color: '#2c3e50',
                  font: {
                    size: 14,
                    weight: 'bold'
                  }
                },
                ticks: {
                  color: '#2c3e50',
                  font: {
                    size: 12
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
            }
          }
        })
  } catch (error) {
    console.error('创建详情图表失败:', error)
  }
}

const refreshDetail = async () => {
  if (selectedService.value && !isRefreshing.value) {
    isRefreshing.value = true
    try {
      // 根据选择的时间范围加载服务详情
      await servicesStore.loadServiceDetail(selectedService.value.id, selectedTimeRange.value)
      await createDetailChart()
    } catch (error) {
      console.error('刷新数据失败:', error)
    } finally {
      isRefreshing.value = false
    }
  }
}

// 开始自动刷新
const startAutoRefresh = () => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
  }
  // 每60秒刷新一次，确保图表数据实时更新
  refreshInterval = setInterval(async () => {
    if (selectedService.value) {
      await servicesStore.loadServiceDetail(selectedService.value.id, selectedTimeRange.value)
      await createDetailChart()
      
      // 如果是今日或昨日，更新小时流量图表
      if (selectedTimeRange.value === 'today' || selectedTimeRange.value === 'yesterday') {
        createHourlyChart()
      }
    }
  }, 60000)
}

// 停止自动刷新
const stopAutoRefresh = () => {
  if (refreshInterval) {
    clearInterval(refreshInterval)
    refreshInterval = null
  }
}

// 加载历史数据
const loadHistoryData = async () => {
  if (!selectedService.value || !historyDateRange.value || historyDateRange.value.length !== 2) return
  
  isLoadingHistory.value = true
  try {
    const [startDate, endDate] = historyDateRange.value
    const response = await servicesAPI.getHistoryTraffic(
      selectedService.value.id, 
      startDate, 
      endDate
    )
    
    if (response.data.success) {
      historyData.value = response.data.data
      createHistoryChart()
    }
  } catch (error) {
    console.error('加载历史数据失败:', error)
    ElMessage.error('加载历史数据失败')
  } finally {
    isLoadingHistory.value = false
  }
}

// 创建历史数据图表
const createHistoryChart = () => {
  try {
    const ctx = document.getElementById('history-chart')
    if (!ctx) {
      console.warn('history-chart canvas element not found')
      return
    }
    
    if (!selectedService.value) {
      console.warn('No selected service available for history chart')
      return
    }
    
    // 准备图表数据
    const labels = historyData.value.dates || []
    const uploadData = historyData.value.upload_data || []
    const downloadData = historyData.value.download_data || []
    
    // 销毁现有图表
    if (historyChart) {
      historyChart.destroy()
      historyChart = null
    }
    
    historyChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: '上传',
            data: uploadData,
            borderColor: '#74b9ff',
            backgroundColor: 'rgba(116, 185, 255, 0.1)',
            tension: 0.4,
            fill: true
          },
          {
            label: '下载',
            data: downloadData,
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
            display: true,
            position: 'top'
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                return context.dataset.label + ': ' + formatBytes(context.parsed.y)
              }
            }
          }
        },
        scales: {
          x: {
            title: {
              display: true,
              text: '日期'
            }
          },
          y: {
            title: {
              display: true,
              text: '流量'
            },
            ticks: {
              callback: function(value) {
                return formatBytes(value)
              }
            }
          }
        }
      }
    })
  } catch (error) {
    console.error('创建历史数据图表失败:', error)
  }
}

const backToHome = () => {
  router.push('/home')
}

const viewPortDetail = (serviceId, tag) => {
  router.push(`/port/${serviceId}/${tag}`)
}

const viewUserDetail = (serviceId, email) => {
  router.push(`/user/${serviceId}/${email}`)
}

// 保留4位有效数字的格式化函数
function formatBytes(num) {
  if (typeof num !== 'number' || isNaN(num)) return '-';
  if (num >= 1024 * 1024 * 1024) {
    return (num / (1024 * 1024 * 1024)).toPrecision(4) + ' GB';
  } else if (num >= 1024 * 1024) {
    return (num / (1024 * 1024)).toPrecision(4) + ' MB';
  } else if (num >= 1024) {
    return (num / 1024).toPrecision(4) + ' KB';
  } else {
    return num + ' B';
  }
}

const sortedInbounds = computed(() => {
  if (!selectedService.value || !Array.isArray(selectedService.value.inbound_traffics)) return [];
  return [...selectedService.value.inbound_traffics].sort((a, b) => b.down - a.down);
});
const sortedClients = computed(() => {
  if (!selectedService.value || !Array.isArray(selectedService.value.client_traffics)) return [];
  return [...selectedService.value.client_traffics].sort((a, b) => b.down - a.down);
});

onMounted(async () => {
  const serviceId = parseInt(route.params.serviceId)
  
  // 如果没有选中的服务，从主页获取
  if (!selectedService.value || selectedService.value.id !== serviceId) {
    // 这里需要从主页获取服务列表，然后选择对应的服务
    await servicesStore.loadServices()
    const service = servicesStore.services.find(s => s.id === serviceId)
    if (service) {
      servicesStore.selectService(service)
    }
  }
  
  // 加载服务详情
  if (selectedService.value) {
    await servicesStore.loadServiceDetail(serviceId)
    
    // 等待 DOM 更新后再创建图表
    await nextTick()
    
    // 初始化图表
    createDetailChart()
    createHourlyChart()
    createHistoryChart()
    
    // 开始自动刷新
    startAutoRefresh()
  }
})

onUnmounted(() => {
  if (detailChart) {
    detailChart.destroy()
  }
  if (hourlyChart) {
    hourlyChart.destroy()
  }
  if (historyChart) {
    historyChart.destroy()
  }
  stopAutoRefresh()
})
</script>

<style scoped>
.table-label-container {
  display: flex;
  align-items: center;
  gap: 8px;
}

.display-name {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 500;
  color: #2c3e50;
}

.edit-icon {
  background: none;
  border: none;
  cursor: pointer;
  font-size: 12px;
  padding: 2px;
  border-radius: 3px;
  transition: all 0.2s ease;
}

.edit-icon:hover {
  background: rgba(52, 152, 219, 0.1);
}

/* 标题中的编辑图标样式 */
.header h1 .edit-icon {
  font-size: 16px;
  padding: 4px;
  margin-left: 8px;
  vertical-align: middle;
}

.header h1 {
  color: #222;
  text-shadow: none;
}
.detail-title {
  color: #222;
}
.section-title {
  color: #222;
}

.chart-section {
  background: white;
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 4px 15px rgba(0,0,0,0.1);
  margin-top: 25px;
  margin-bottom: 25px;
}

.chart-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.section-title {
  font-size: 1.2rem;
  font-weight: bold;
  color: #2c3e50;
  margin: 0;
}

.time-range-selector {
  display: flex;
  gap: 8px;
}

.time-range-button {
  padding: 6px 12px;
  border-radius: 20px;
  border: 1px solid #e0e0e0;
  background: #f5f5f5;
  color: #666;
  cursor: pointer;
  font-size: 14px;
  transition: all 0.3s ease;
}

.time-range-button:hover {
  background: #e8f4fc;
  border-color: #a8d8ff;
}

.time-range-button.active {
  background: #3498db;
  color: white;
  border-color: #3498db;
}

.chart-container {
  height: 300px;
  position: relative;
}

.hourly-traffic-container {
  margin-top: 10px;
}

.hourly-chart-container {
  height: 250px;
  position: relative;
}

.history-chart-container {
  height: 300px;
  width: 100%;
  position: relative;
}

.refresh-button {
  background: #70A1FF;
  color: #fff;
  border: none;
  padding: 10px 20px;
  border-radius: 20px;
  cursor: pointer;
  font-size: 0.9rem;
  font-weight: 600;
  box-shadow: 0 2px 8px rgba(112,161,255,0.10);
  transition: background 0.2s, color 0.2s, box-shadow 0.2s, transform 0.18s;
  position: relative;
  overflow: hidden;
}

.refresh-button:hover:not(:disabled) {
  background: #1E90FF;
  color: #fff;
  transform: translateY(-1px);
  box-shadow: 0 4px 16px rgba(112,161,255,0.18);
}

.refresh-button:disabled {
  background: #d1d1d6;
  color: #fff;
  cursor: not-allowed;
  transform: none;
  box-shadow: none;
}

.table-row {
  border-left: 3px solid #70A1FF;
}

.container {
  max-width: 900px;
  margin: 0 auto;
  padding: 0 24px;
}
</style>