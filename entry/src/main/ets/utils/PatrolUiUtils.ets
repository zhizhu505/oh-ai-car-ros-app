import { AlertLevel, ChannelStatus, PatrolStatus } from '../model/PatrolModels';

export function levelColor(level: AlertLevel): ResourceColor {
  if (level === AlertLevel.Critical) {
    return $r('app.color.alert_critical');
  }
  if (level === AlertLevel.Warning) {
    return $r('app.color.alert_warning');
  }
  return $r('app.color.alert_normal');
}

export function patrolStatusColor(status: PatrolStatus): ResourceColor {
  switch (status) {
    case PatrolStatus.Alerting:
      return $r('app.color.alert_critical');
    case PatrolStatus.Avoiding:
      return $r('app.color.alert_warning');
    case PatrolStatus.Patrolling:
    case PatrolStatus.Navigating:
    case PatrolStatus.Returning:
      return $r('app.color.status_active');
    case PatrolStatus.Paused:
      return $r('app.color.alert_warning');
    default:
      return $r('app.color.card_background');
  }
}

export function channelStatusColor(status: ChannelStatus): ResourceColor {
  if (status === ChannelStatus.Blocked || status === ChannelStatus.Occupied) {
    return $r('app.color.alert_critical');
  }
  if (status === ChannelStatus.SlowDown) {
    return $r('app.color.alert_warning');
  }
  return $r('app.color.alert_normal');
}

export function onlineColor(online: boolean): ResourceColor {
  return online ? $r('app.color.alert_normal') : $r('app.color.alert_critical');
}
