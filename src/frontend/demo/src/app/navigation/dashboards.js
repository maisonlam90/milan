import DashboardsIcon from 'assets/dualicons/dashboards.svg?react'
import StatisticIcon from 'assets/nav-icons/statistic.svg?react'
import WindowIcon from 'assets/nav-icons/window.svg?react'
import OrderTimerIcon from 'assets/nav-icons/shopping-cart.svg?react'
import PersonalChartIcon from 'assets/nav-icons/personal-chart.svg?react'
import BtcIcon from 'assets/nav-icons/btc.svg?react'
import BankBuildIcon from 'assets/nav-icons/bank-build.svg?react'
import Statistic2Icon from 'assets/nav-icons/statistic-2.svg?react'
import MegaphoneIcon from 'assets/nav-icons/megaphone.svg?react'
import MapIcon from 'assets/nav-icons/map.svg?react'
import StudentIcon from 'assets/nav-icons/student.svg?react'
import StethoscopeIcon from 'assets/nav-icons/stethoscope.svg?react'
import PeopleIcon from 'assets/nav-icons/people.svg?react'
import PeopleEditIcon from 'assets/nav-icons/people-edit.svg?react'
import PeopleMonitorIcon from 'assets/nav-icons/people-monitor.svg?react'
import TeacherIcon from 'assets/nav-icons/teacher.svg?react'
import MonitorIcon from 'assets/nav-icons/monitor.svg?react'
import ProjectBoardIcon from 'assets/nav-icons/project-board.svg?react'
import WidgetIcon from 'assets/nav-icons/widget.svg?react'
import { NAV_TYPE_ROOT, NAV_TYPE_ITEM, NAV_TYPE_COLLAPSE, NAV_TYPE_DIVIDER } from 'constants/app.constant'

const ROOT_DASHBOARDS = '/dashboards'

const path = (root, item) => `${root}${item}`;


/**
 * Lọc cây menu theo module được phép.
 * - allowed: Set(['acl','user','loan','payment',...])
 * - Giữ node nếu:
 *   + node.public === true (luôn hiển thị), HOẶC
 *   + node.moduleKey thuộc allowed, HOẶC
 *   + node có children sau khi filter (collapse/group)
 */
export function filterByAcl(node, allowed) {
  // Node copy nông
  const n = { ...node }
  // Divider giữ lại nếu có public, còn không thì bỏ để menu gọn
  if (n.type === NAV_TYPE_DIVIDER) {
    return n.public ? n : null
  }
  // Filter children (nếu có)
  if (Array.isArray(n.childs)) {
    const filtered = n.childs
      .map(child => filterByAcl(child, allowed))
      .filter(Boolean)
    n.childs = filtered
  }
  const hasChildren = Array.isArray(n.childs) && n.childs.length > 0

  // Quy tắc hiển thị
  const isAllowed = n.public === true || (n.moduleKey && allowed.has(n.moduleKey)) || hasChildren

  return isAllowed ? n : null
}

export const dashboards = {
    id: 'dashboards',
    type: NAV_TYPE_ROOT,
    path: '/dashboards',
    title: 'Dashboards',
    transKey: 'nav.dashboards.dashboards',
    Icon: DashboardsIcon,
    childs: [
        {
            id: 'dashboards.tenants',
            path: path(ROOT_DASHBOARDS, '/tenants'),
            type: NAV_TYPE_ITEM,
            title: 'Tenants',
            transKey: 'nav.dashboards.tenants',
            Icon: PeopleIcon,
            moduleKey: 'tenant',
        },
        {
            id: 'dashboards.user',
            path: path(ROOT_DASHBOARDS, '/user'),
            type: NAV_TYPE_ITEM,
            title: 'User',
            transKey: 'nav.dashboards.user',
            Icon: PeopleIcon,
            moduleKey: 'user',
        },
        {
            id: 'dashboards.iam',
            path: path(ROOT_DASHBOARDS, '/iam'),
            type: NAV_TYPE_ITEM,
            title: 'Iam',
            transKey: 'nav.dashboards.iam',
            Icon: PeopleIcon,
        },
        {
            id: 'dashboards.contact',
            path: path(ROOT_DASHBOARDS, '/contact'),
            type: NAV_TYPE_COLLAPSE,
            title: 'Contact',
            transKey: 'nav.dashboards.contact',
            Icon: PeopleIcon,
            childs: [
                {
                    id: 'dashboards.contact-list',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/contact/contact-list'),
                    title: 'contact list',
                    transKey: 'nav.dashboards.contact-list',
                },
                {
                    id: 'dashboards.contact-create',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/contact/contact-create'),
                    title: 'contact create',
                    transKey: 'nav.dashboards.contact-create',
                },
            ],
        },
        {
            id: 'dashboards.loan',
            path: path(ROOT_DASHBOARDS, '/loan'),
            type: NAV_TYPE_COLLAPSE,
            title: 'Loan',
            transKey: 'nav.dashboards.loan',
            Icon: PeopleIcon,
            childs: [
                {
                    id: 'dashboards.loan-dashboard',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/loan/loan-dashboard'),
                    title: 'loan v1',
                    transKey: 'nav.dashboards.loan-dashboard',
                },
                {
                    id: 'dashboards.loan-list',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/loan/loan-list'),
                    title: 'loan v1',
                    transKey: 'nav.dashboards.loan-list',
                },
                {
                    id: 'dashboards.loan-create',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/loan/loan-create'),
                    title: 'loan v2',
                    transKey: 'nav.dashboards.loan-create',
                },
                {
                    id: 'dashboards.loan-collateral',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/loan/loan-collateral'),
                    title: 'loan collateral',
                    transKey: 'nav.dashboards.loan-collateral',
                },
            ],
        },
        {
            id: 'dashboards.sales',
            path: path(ROOT_DASHBOARDS, '/sales'),
            type: NAV_TYPE_ITEM,
            title: 'Sales',
            transKey: 'nav.dashboards.sales',
            Icon: StatisticIcon,
        },
        {
            id: 'dashboards.crm-analytics',
            path: path(ROOT_DASHBOARDS, '/crm-analytics'),
            type: NAV_TYPE_ITEM,
            title: 'CRM Analytics',
            transKey: 'nav.dashboards.crm-analytics',
            Icon: WindowIcon,
        },
        {
            id: 'dashboards.orders',
            path: path(ROOT_DASHBOARDS, '/orders'),
            type: NAV_TYPE_ITEM,
            title: 'Orders',
            transKey: 'nav.dashboards.orders',
            Icon: OrderTimerIcon,
        },
        {
            id: 'dashboards.divide-1',
            type: NAV_TYPE_DIVIDER
        },
        {
            id: 'dashboards.crypto',
            path: path(ROOT_DASHBOARDS, '/crypto'),
            type: NAV_TYPE_COLLAPSE,
            title: 'Cryptocurrency',
            transKey: 'nav.dashboards.crypto',
            Icon: BtcIcon,
            childs: [
                {
                    id: 'dashboards.crypto-1',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/crypto/crypto-1'),
                    title: 'Cryptocurrency v1',
                    transKey: 'nav.dashboards.crypto-1',
                },
                {
                    id: 'dashboards.crypto-2',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/crypto/crypto-2'),
                    title: 'Cryptocurrency v2',
                    transKey: 'nav.dashboards.crypto-2',
                },
            ],

        },
        {
            id: 'dashboards.banking',
            path: path(ROOT_DASHBOARDS, '/banking'),
            type: NAV_TYPE_COLLAPSE,
            title: 'Cryptocurrency',
            transKey: 'nav.dashboards.banking',
            Icon: BankBuildIcon,
            childs: [
                {
                    id: 'dashboards.banking-1',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/banking/banking-1'),
                    title: 'Banking v1',
                    transKey: 'nav.dashboards.banking-1',
                },
                {
                    id: 'dashboards.banking-2',
                    type: NAV_TYPE_ITEM,
                    path: path(ROOT_DASHBOARDS, '/banking/banking-2'),
                    title: 'Banking v2',
                    transKey: 'nav.dashboards.banking-2',
                },
            ],

        },
        {
            id: 'dashboards.personal',
            path: path(ROOT_DASHBOARDS, '/personal'),
            type: NAV_TYPE_ITEM,
            title: 'Personal',
            transKey: 'nav.dashboards.personal',
            Icon: PersonalChartIcon,
        },
        {
            id: 'dashboards.cms-analytics',
            path: path(ROOT_DASHBOARDS, '/cms-analytics'),
            type: NAV_TYPE_ITEM,
            title: 'CMS Analytics',
            transKey: 'nav.dashboards.cms-analytics',
            Icon: Statistic2Icon,
        },
        {
            id: 'dashboards.influencer',
            path: path(ROOT_DASHBOARDS, '/influencer'),
            type: NAV_TYPE_ITEM,
            title: 'Influencer',
            transKey: 'nav.dashboards.influencer',
            Icon: MegaphoneIcon,
        },
        {
            id: 'dashboards.travel',
            path: path(ROOT_DASHBOARDS, '/travel'),
            type: NAV_TYPE_ITEM,
            title: 'Travel',
            transKey: 'nav.dashboards.travel',
            Icon: MapIcon,
        },
        {
            id: 'dashboards.teacher',
            path: path(ROOT_DASHBOARDS, '/teacher'),
            type: NAV_TYPE_ITEM,
            title: 'Teacher',
            transKey: 'nav.dashboards.teacher',
            Icon: TeacherIcon,
        },
        {
            id: 'dashboards.education',
            path: path(ROOT_DASHBOARDS, '/education'),
            type: NAV_TYPE_ITEM,
            title: 'Education',
            transKey: 'nav.dashboards.education',
            Icon: StudentIcon,
        },
        {
            id: 'dashboards.authors',
            path: path(ROOT_DASHBOARDS, '/authors'),
            type: NAV_TYPE_ITEM,
            title: 'Authors',
            transKey: 'nav.dashboards.authors',
            Icon: PeopleEditIcon,
        },
        {
            id: 'dashboards.doctor',
            path: path(ROOT_DASHBOARDS, '/doctor'),
            type: NAV_TYPE_ITEM,
            title: 'Doctor',
            transKey: 'nav.dashboards.doctor',
            Icon: StethoscopeIcon,
        },
        {
            id: 'dashboards.employees',
            path: path(ROOT_DASHBOARDS, '/employees'),
            type: NAV_TYPE_ITEM,
            title: 'Employees',
            transKey: 'nav.dashboards.employees',
            Icon: PeopleIcon,
        },
        {
            id: 'dashboards.workspaces',
            path: path(ROOT_DASHBOARDS, '/workspaces'),
            type: NAV_TYPE_ITEM,
            title: 'Workspaces',
            transKey: 'nav.dashboards.workspaces',
            Icon: MonitorIcon,
        },
        {
            id: 'dashboards.meetings',
            path: path(ROOT_DASHBOARDS, '/meetings'),
            type: NAV_TYPE_ITEM,
            title: 'Meetings',
            transKey: 'nav.dashboards.meetings',
            Icon: PeopleMonitorIcon,
        },
        {
            id: 'dashboards.projects-board',
            path: path(ROOT_DASHBOARDS, '/projects-board'),
            type: NAV_TYPE_ITEM,
            title: 'Projects Board',
            transKey: 'nav.dashboards.projects-board',
            Icon: ProjectBoardIcon,
        },
        {
            id: 'dashboards.divide-2',
            type: NAV_TYPE_DIVIDER
        },
        {
            id: 'dashboards.widget-ui',
            path: path(ROOT_DASHBOARDS, '/widget-ui'),
            type: NAV_TYPE_ITEM,
            title: 'Widgets UI',
            transKey: 'nav.dashboards.widget-ui',
            Icon: WidgetIcon,
        },
        {
            id: 'dashboards.widget-contact',
            path: path(ROOT_DASHBOARDS, '/widget-contact'),
            type: NAV_TYPE_ITEM,
            title: 'Widgets Contact',
            transKey: 'nav.dashboards.widget-contact',
            Icon: WidgetIcon,
        },
    ]
}
