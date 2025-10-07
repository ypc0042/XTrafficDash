import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { servicesAPI } from '@/utils/api'

export const useServicesStore = defineStore('services', () => {
  const services = ref([])
  const selectedService = ref(null)
  const loading = ref(false)
  const error = ref(null)
  const refreshInterval = ref(null)

  const loadServices = async () => {
    loading.value = true
    error.value = null
    
    try {
      const response = await servicesAPI.getServices()
      if (response.data.success) {
        services.value = response.data.data
      } else {
        error.value = response.data.message || '加载服务列表失败'
      }
    } catch (err) {
      console.error('加载服务列表失败:', err)
      if (err.response?.status === 401) {
        error.value = '认证失败，请重新登录'
      } else {
        error.value = '网络错误，请检查服务器连接'
      }
    } finally {
      loading.value = false
    }
  }

  const selectService = (service) => {
    selectedService.value = service
  }

  const loadServiceDetail = async (serviceId, timeRange = 'today') => {
    try {
      // 根据时间范围构建API请求
      let response
      if (timeRange === 'today') {
        response = await servicesAPI.getServiceDetail(serviceId)
      } else {
        response = await servicesAPI.getServiceDetailWithTimeRange(serviceId, timeRange)
      }
      
      if (response.data.success) {
        selectedService.value = {
          ...selectedService.value,
          ...response.data.data,
          currentTimeRange: timeRange // 记录当前选择的时间范围
        }
        
        // 加载不同时间范围的流量数据
        await loadTimeRangeTraffic(serviceId)
      }
    } catch (error) {
      console.error('加载服务详情失败:', error)
    }
  }
  
  // 加载不同时间范围的流量数据
  const loadTimeRangeTraffic = async (serviceId) => {
    try {
      // 加载今日流量数据
      const todayResponse = await servicesAPI.getTodayTraffic(serviceId)
      if (todayResponse.data.success) {
        selectedService.value.today_traffic_data = todayResponse.data.data
        selectedService.value.today_inbound_up = calculateTotalTraffic(todayResponse.data.data.upload_data)
        selectedService.value.today_inbound_down = calculateTotalTraffic(todayResponse.data.data.download_data)
      }
      
      // 加载昨日流量数据
      const yesterdayResponse = await servicesAPI.getYesterdayTraffic(serviceId)
      if (yesterdayResponse.data.success) {
        selectedService.value.yesterday_traffic_data = yesterdayResponse.data.data
        selectedService.value.yesterday_inbound_up = calculateTotalTraffic(yesterdayResponse.data.data.upload_data)
        selectedService.value.yesterday_inbound_down = calculateTotalTraffic(yesterdayResponse.data.data.download_data)
      }
      
      // 加载近3日流量数据
      const last3DaysResponse = await servicesAPI.getLast3DaysTraffic(serviceId)
      if (last3DaysResponse.data.success) {
        selectedService.value.last3days_traffic_data = last3DaysResponse.data.data
        selectedService.value.last3days_inbound_up = calculateTotalTraffic(last3DaysResponse.data.data.upload_data)
        selectedService.value.last3days_inbound_down = calculateTotalTraffic(last3DaysResponse.data.data.download_data)
      }
    } catch (error) {
      console.error('加载时间范围流量数据失败:', error)
    }
  }
  
  // 计算总流量
  const calculateTotalTraffic = (trafficArray) => {
    if (!trafficArray || !Array.isArray(trafficArray)) return 0
    return trafficArray.reduce((sum, current) => sum + current, 0)
  }

  const deleteService = async (serviceId) => {
    try {
      const response = await servicesAPI.deleteService(serviceId)
      if (response.data.success) {
        services.value = services.value.filter(s => s.id !== serviceId)
        return { success: true }
      } else {
        return { success: false, error: response.data.message }
      }
    } catch (error) {
      console.error('删除服务失败:', error)
      return { success: false, error: '删除失败，请重试' }
    }
  }

  // 开始自动刷新
  const startAutoRefresh = () => {
    if (refreshInterval.value) {
      clearInterval(refreshInterval.value)
    }
    // 每60秒刷新一次
    refreshInterval.value = setInterval(() => {
      loadServices()
    }, 60000)
  }

  // 停止自动刷新
  const stopAutoRefresh = () => {
    if (refreshInterval.value) {
      clearInterval(refreshInterval.value)
      refreshInterval.value = null
    }
  }

  // 强制刷新
  const forceRefresh = () => {
    loadServices()
    if (selectedService.value) {
      loadServiceDetail(selectedService.value.id)
    }
  }

  return {
    services: computed(() => services.value),
    selectedService: computed(() => selectedService.value),
    loading: computed(() => loading.value),
    error: computed(() => error.value),
    loadServices,
    selectService,
    loadServiceDetail,
    deleteService,
    startAutoRefresh,
    stopAutoRefresh,
    forceRefresh
  }
})