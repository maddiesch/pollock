# pollock

An iOS Drawing Engine

### File Format

The drawing files are `Libz` compressed JSON files.

Format:

```json
{
  "header": {
    "version": 1,
    "context_id": "5E26F302-A051-40FB-9E8F-50411AB9C38D",
    "count": 4
  },
  "drawings": [{
    "points": [{
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 184.5,
        "x": 248
      },
      "location": {
        "y": 184.5,
        "x": 248
      }
    }, {
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 184.5,
        "x": 248
      },
      "location": {
        "y": 184,
        "x": 234
      }
    }],
    "count": 2,
    "tool": {
      "force": 8,
      "name": "pen",
      "version": 1,
      "lineWidth": 16
    },
    "version": 1,
    "size": [760, 966],
    "smoothing": 8,
    "drawing_id": "1DB6A8BA-E2D4-48BC-A1E7-D9EE2E51204B"
  }, {
    "points": [{
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 233,
        "x": 254.5
      },
      "location": {
        "y": 233,
        "x": 254.5
      }
    }, {
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 233,
        "x": 254.5
      },
      "location": {
        "y": 233.5,
        "x": 254.5
      }
    }],
    "count": 2,
    "tool": {
      "force": 8,
      "name": "pen",
      "version": 1,
      "lineWidth": 16
    },
    "version": 1,
    "size": [760, 966],
    "smoothing": 8,
    "drawing_id": "EA4261F2-BDB4-482D-8430-EE5430269023",
    "isCulled": false
  }, {
    "points": [{
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 235,
        "x": 297
      },
      "location": {
        "y": 235,
        "x": 297
      }
    }, {
      "force": 1,
      "isPredictive": false,
      "previous": {
        "y": 235,
        "x": 297
      },
      "location": {
        "y": 235.5,
        "x": 297
      }
    }],
    "count": 2,
    "tool": {
      "force": 8,
      "name": "pen",
      "version": 1,
      "lineWidth": 16
    },
    "version": 1,
    "size": [760, 966],
    "smoothing": 8,
    "drawing_id": "C29AE3F8-B309-4709-9293-2A6A8A34216B"
  }]
}
```

##### `header` (Object)

The document header.

###### Keys

- `version`: The version number of the json structure.

- `context_id`: A v4 UUID of the drawing context. Can also be used as an ID for the drawing itself.

- `count`: The total number of `drawings` in the file

##### `drawings` (Array)

The individual drawings that make up this document.

##### `drawing` (Object)

The actual drawing object that is contained in the `drawings` array.

###### Keys

- `drawing_id`: A v4 UUID.

- `version`: The version of the JSON structure.

- `smoothing`: The smoothing rate that should be used when drawing this path. (Catmull–Rom spline granularity)

- `size`: The canvas size for the drawing. All drawings coordinate system is from the top left corner.

- `count`: Number of points in this drawing.

- `meta`: Additional information about the drawing.

- `tool`: The tool used to create this drawing.

- `points`: An array of point objects.

- `isCulled`: A bool indicating if the drawing should be culled from the render tree.

##### `point` (Object)

An individual point in the drawing.

###### Keys

- `force`: A number representing the amount of force used when creating this point. (Default 1)

- `isPredictive`: This point was generated as a prediction of where the user was drawing. Created by the system. (The drawing document shouldn't contain any `true` predictive points).

- `previous`: (Object) A reference to the previous location. If it's the first point in the drawing this will be the same as `location`. This is stored for drawing performance reasons.

  - `x`: The X location of the previous point.

  - `y`: The y location of the previous point.

- `location`:

  - `x`: The x location of the point.

  - `y`: The y location of the point.

##### `tool` (Object)

The tool used to create this drawing.

- `force`: The force cap of the tool.

- `name`: The name of the tool. (Tool Type)

- `version`: The version of the JSON structure.

- `lineWidth`: How wide the line should be drawn.
