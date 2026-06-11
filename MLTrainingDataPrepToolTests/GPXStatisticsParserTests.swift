//
//  GPXStatisticsParserTests.swift
//  MLTrainingDataPrepToolTests
//
//  Created by Damien Glancy on 11/06/2026.
//

import Foundation
import Testing

@Suite("GPXStatisticsParser")
struct GPXStatisticsParserTests {

  // MARK: - Valid GPX

  @Test
  func parsesAllStatisticsFromValidGPX() throws {
    let statistics = try GPXStatisticsParser().parse(data: Data(Self.validGPX.utf8))

    #expect(statistics.name == "Ashtown, Dublin 15 → Castleknock, Dublin 15")
    #expect(statistics.distanceMetres == 11917.1)
    #expect(statistics.durationSeconds == 1800)
    #expect(statistics.averageSpeedKmh == 7.9)
    #expect(statistics.meanSpeedKmh == 9.3)
    #expect(statistics.speedStandardDeviationKmh == 15.9)
    #expect(statistics.speedVarianceKmh2 == 253.4)
    #expect(statistics.percentTimeAbove80Kmh == 0.0)
    #expect(statistics.sustainedHighSpeedSegmentCount == 0)
    #expect(statistics.stopCount == 18)
    #expect(statistics.percentTimeStopped == 56.7)
    #expect(statistics.sinuosity == 268.980)
    #expect(statistics.bearingChangeRateDegreesPerKilometre == 3853.8)
    #expect(statistics.elevationGainMetres == 194.7)
    #expect(statistics.elevationLossMetres == 205.1)
  }

  // MARK: - Errors

  @Test
  func throwsMissingStatsBlockWhenExtensionsAreAbsent() {
    #expect(throws: GPXParsingError.missingStatsBlock) {
      try GPXStatisticsParser().parse(data: Data(Self.gpxWithoutStats.utf8))
    }
  }

  @Test
  func throwsMalformedXMLForInvalidData() {
    #expect(throws: GPXParsingError.malformedXML) {
      try GPXStatisticsParser().parse(data: Data("not xml".utf8))
    }
  }

  @Test
  func throwsMissingFieldForMissingDoubleField() {
    #expect(throws: GPXParsingError.missingField("drv:distanceMetres")) {
      try GPXStatisticsParser().parse(data: Data(Self.gpxMissingDistance.utf8))
    }
  }

  @Test
  func throwsMissingFieldForMissingIntField() {
    #expect(throws: GPXParsingError.missingField("drv:durationSeconds")) {
      try GPXStatisticsParser().parse(data: Data(Self.gpxMissingDuration.utf8))
    }
  }

  @Test
  func errorDescriptionsAreUserFacing() {
    #expect(GPXParsingError.malformedXML.errorDescription?.isEmpty == false)
    #expect(GPXParsingError.missingStatsBlock.errorDescription?.isEmpty == false)
    #expect(GPXParsingError.missingField("drv:distanceMetres").errorDescription?.contains("drv:distanceMetres") == true)
  }

  // MARK: - Fixtures

  private static let validGPX = """
  <?xml version="1.0" encoding="UTF-8"?>
  <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:drv="https://www.targatrips.com/gpx/v1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" version="1.1" creator="Driveline for iOS">
    <trk>
      <name>Ashtown, Dublin 15 → Castleknock, Dublin 15</name>
      <extensions>
        <drv:stats>
          <drv:distanceMetres>11917.1</drv:distanceMetres>
          <drv:durationSeconds>1800</drv:durationSeconds>
          <drv:averageSpeedKmh>7.9</drv:averageSpeedKmh>
          <drv:meanSpeedKmh>9.3</drv:meanSpeedKmh>
          <drv:speedStandardDeviationKmh>15.9</drv:speedStandardDeviationKmh>
          <drv:speedVarianceKmh2>253.4</drv:speedVarianceKmh2>
          <drv:percentTimeAbove80Kmh>0.0</drv:percentTimeAbove80Kmh>
          <drv:sustainedHighSpeedSegmentCount>0</drv:sustainedHighSpeedSegmentCount>
          <drv:stopCount>18</drv:stopCount>
          <drv:percentTimeStopped>56.7</drv:percentTimeStopped>
          <drv:sinuosity>268.980</drv:sinuosity>
          <drv:bearingChangeRateDegreesPerKilometre>3853.8</drv:bearingChangeRateDegreesPerKilometre>
          <drv:elevationGainMetres>194.7</drv:elevationGainMetres>
          <drv:elevationLossMetres>205.1</drv:elevationLossMetres>
        </drv:stats>
      </extensions>
      <trkseg>
        <trkpt lat="53.375883400000006" lon="-6.332005999999999">
          <ele>50.8</ele>
          <time>2026-06-11T12:01:55Z</time>
        </trkpt>
      </trkseg>
    </trk>
  </gpx>
  """

  private static let gpxMissingDistance = """
  <?xml version="1.0" encoding="UTF-8"?>
  <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:drv="https://www.targatrips.com/gpx/v1" version="1.1" creator="Driveline for iOS">
    <trk>
      <name>Missing Distance</name>
      <extensions>
        <drv:stats>
          <drv:durationSeconds>1800</drv:durationSeconds>
          <drv:averageSpeedKmh>7.9</drv:averageSpeedKmh>
          <drv:meanSpeedKmh>9.3</drv:meanSpeedKmh>
          <drv:speedStandardDeviationKmh>15.9</drv:speedStandardDeviationKmh>
          <drv:speedVarianceKmh2>253.4</drv:speedVarianceKmh2>
          <drv:percentTimeAbove80Kmh>0.0</drv:percentTimeAbove80Kmh>
          <drv:sustainedHighSpeedSegmentCount>0</drv:sustainedHighSpeedSegmentCount>
          <drv:stopCount>18</drv:stopCount>
          <drv:percentTimeStopped>56.7</drv:percentTimeStopped>
          <drv:sinuosity>268.980</drv:sinuosity>
          <drv:bearingChangeRateDegreesPerKilometre>3853.8</drv:bearingChangeRateDegreesPerKilometre>
          <drv:elevationGainMetres>194.7</drv:elevationGainMetres>
          <drv:elevationLossMetres>205.1</drv:elevationLossMetres>
        </drv:stats>
      </extensions>
      <trkseg>
        <trkpt lat="53.0" lon="-6.0">
          <ele>10.0</ele>
          <time>2026-06-11T12:01:55Z</time>
        </trkpt>
      </trkseg>
    </trk>
  </gpx>
  """

  private static let gpxMissingDuration = """
  <?xml version="1.0" encoding="UTF-8"?>
  <gpx xmlns="http://www.topografix.com/GPX/1/1" xmlns:drv="https://www.targatrips.com/gpx/v1" version="1.1" creator="Driveline for iOS">
    <trk>
      <name>Missing Duration</name>
      <extensions>
        <drv:stats>
          <drv:distanceMetres>11917.1</drv:distanceMetres>
          <drv:averageSpeedKmh>7.9</drv:averageSpeedKmh>
          <drv:meanSpeedKmh>9.3</drv:meanSpeedKmh>
          <drv:speedStandardDeviationKmh>15.9</drv:speedStandardDeviationKmh>
          <drv:speedVarianceKmh2>253.4</drv:speedVarianceKmh2>
          <drv:percentTimeAbove80Kmh>0.0</drv:percentTimeAbove80Kmh>
          <drv:sustainedHighSpeedSegmentCount>0</drv:sustainedHighSpeedSegmentCount>
          <drv:stopCount>18</drv:stopCount>
          <drv:percentTimeStopped>56.7</drv:percentTimeStopped>
          <drv:sinuosity>268.980</drv:sinuosity>
          <drv:bearingChangeRateDegreesPerKilometre>3853.8</drv:bearingChangeRateDegreesPerKilometre>
          <drv:elevationGainMetres>194.7</drv:elevationGainMetres>
          <drv:elevationLossMetres>205.1</drv:elevationLossMetres>
        </drv:stats>
      </extensions>
      <trkseg>
        <trkpt lat="53.0" lon="-6.0">
          <ele>10.0</ele>
          <time>2026-06-11T12:01:55Z</time>
        </trkpt>
      </trkseg>
    </trk>
  </gpx>
  """

  private static let gpxWithoutStats = """
  <?xml version="1.0" encoding="UTF-8"?>
  <gpx xmlns="http://www.topografix.com/GPX/1/1" version="1.1" creator="Driveline for iOS">
    <trk>
      <name>No Stats</name>
      <trkseg>
        <trkpt lat="53.0" lon="-6.0">
          <ele>10.0</ele>
          <time>2026-06-11T12:01:55Z</time>
        </trkpt>
      </trkseg>
    </trk>
  </gpx>
  """
}
