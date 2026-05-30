//
//  HomeViewModelTests.swift
//  AutoRouteTests
//
//  Created by Damien Glancy on 30/05/2026.
//

import Testing
import Foundation
@testable import AutoRoute

@Suite("HomeViewModel")
@MainActor
struct HomeViewModelTests {

  // MARK: - Empty State

  @Test
  func emptyRoutesProducesNoSections() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  // MARK: - Section Titles

  @Test
  func todayRouteCreatesTodaySection() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Today")
  }

  @Test
  func yesterdayRouteCreatesYesterdaySection() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 1)])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == "Yesterday")
  }

  @Test
  func routeTwoDaysAgoCreatesDayNameSection() {
    let viewModel = HomeViewModel()
    let route = makeRoute(daysAgo: 2)
    viewModel.update(with: [route])
    let expected = route.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSixDaysAgoStillCreatesDayNameSection() {
    let viewModel = HomeViewModel()
    let route = makeRoute(daysAgo: 6)
    viewModel.update(with: [route])
    let expected = route.startedAt.formatted(.dateTime.weekday(.wide))
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeSevenDaysAgoCreatesMonthYearSection() {
    let viewModel = HomeViewModel()
    let route = makeRoute(daysAgo: 7)
    viewModel.update(with: [route])
    let expected = route.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  @Test
  func routeThirtyDaysAgoCreatesMonthYearSection() {
    let viewModel = HomeViewModel()
    let route = makeRoute(daysAgo: 30)
    viewModel.update(with: [route])
    let expected = route.startedAt.formatted(.dateTime.month(.wide).year())
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].title == expected)
  }

  // MARK: - Grouping

  @Test
  func routesOnSameDayAreGroupedIntoOneSection() {
    let viewModel = HomeViewModel()
    let morning = makeRoute(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeRoute(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections.count == 1)
    #expect(viewModel.sections[0].routes.count == 2)
  }

  @Test
  func routesOnDifferentDaysProduceSeparateSections() {
    let viewModel = HomeViewModel()
    let today = makeRoute(name: "Today", daysAgo: 0)
    let yesterday = makeRoute(name: "Yesterday", daysAgo: 1)
    let older = makeRoute(name: "Older", daysAgo: 10)
    viewModel.update(with: [today, yesterday, older])
    #expect(viewModel.sections.count == 3)
  }

  @Test
  func routesFromSameOlderMonthAreGroupedIntoOneSection() {
    let viewModel = HomeViewModel()
    let a = makeRoute(name: "Route A", daysAgo: 30, hour: 8)
    let b = makeRoute(name: "Route B", daysAgo: 30, hour: 14)
    viewModel.update(with: [a, b])

    let expectedTitle = a.startedAt.formatted(.dateTime.month(.wide).year())
    let bTitle = b.startedAt.formatted(.dateTime.month(.wide).year())

    if expectedTitle == bTitle {
      #expect(viewModel.sections.count == 1)
      #expect(viewModel.sections[0].routes.count == 2)
    }
  }

  // MARK: - Ordering

  @Test
  func sectionsAreOrderedNewestFirst() {
    let viewModel = HomeViewModel()
    let today = makeRoute(name: "Today", daysAgo: 0)
    let yesterday = makeRoute(name: "Yesterday", daysAgo: 1)
    let lastWeek = makeRoute(name: "Last Week", daysAgo: 5)
    viewModel.update(with: [lastWeek, yesterday, today])
    #expect(viewModel.sections[0].title == "Today")
    #expect(viewModel.sections[1].title == "Yesterday")
  }

  @Test
  func routesWithinSectionAreOrderedNewestFirst() {
    let viewModel = HomeViewModel()
    let morning = makeRoute(name: "Morning", daysAgo: 0, hour: 8)
    let afternoon = makeRoute(name: "Afternoon", daysAgo: 0, hour: 14)
    viewModel.update(with: [morning, afternoon])
    #expect(viewModel.sections[0].routes[0].name == "Afternoon")
    #expect(viewModel.sections[0].routes[1].name == "Morning")
  }

  // MARK: - Summary Line

  @Test
  func summaryLineIsNilWhenNoRoutes() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [])
    #expect(viewModel.summaryLine == nil)
  }

  @Test
  func summaryLineIsNilWhenAllRoutesOlderThan30Days() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 31), makeRoute(daysAgo: 60)])
    #expect(viewModel.summaryLine == nil)
  }

  @Test
  func summaryLineIncludesCountOfRoutesInWindow() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [
      makeRoute(daysAgo: 0),
      makeRoute(daysAgo: 5),
      makeRoute(daysAgo: 31)
    ])
    let summary = try! #require(viewModel.summaryLine)
    #expect(summary.hasPrefix("2 routes"))
  }

  @Test
  func summaryLineUsesSingularForOneRoute() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 0)])
    let summary = try! #require(viewModel.summaryLine)
    #expect(summary.hasPrefix("1 route ·"))
  }

  @Test
  func summaryLineContainsKmSuffix() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 0)])
    let summary = try! #require(viewModel.summaryLine)
    #expect(summary.contains("km in the last 30 days"))
  }

  @Test
  func summaryLineIsNilAfterUpdateWithNoRecentRoutes() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 0)])
    #expect(viewModel.summaryLine != nil)
    viewModel.update(with: [makeRoute(daysAgo: 60)])
    #expect(viewModel.summaryLine == nil)
  }

  // MARK: - Update

  @Test
  func callingUpdateReplacesPreviousSections() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(daysAgo: 0)])
    #expect(viewModel.sections.count == 1)
    viewModel.update(with: [])
    #expect(viewModel.sections.isEmpty)
  }

  @Test
  func sectionsReflectLatestRouteSet() {
    let viewModel = HomeViewModel()
    viewModel.update(with: [makeRoute(name: "A", daysAgo: 0)])
    viewModel.update(with: [makeRoute(name: "B", daysAgo: 0), makeRoute(name: "C", daysAgo: 1)])
    #expect(viewModel.sections.count == 2)
    #expect(viewModel.sections[0].routes[0].name == "B")
  }
}

// MARK: - Helpers

private func makeRoute(name: String = "Test Route", daysAgo: Int, hour: Int = 9) -> Route {
  let calendar = Calendar.current
  let day = calendar.date(byAdding: .day, value: -daysAgo, to: .now)!
  let date = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
  let route = Route(name: name)
  route.startedAt = date
  return route
}
