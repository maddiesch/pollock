# pollock

An iOS Drawing Engine

### File Format

The project files are `Libz` compressed JSON files.

Format:

```json
{
  "canvases": [
    {
      "_type": "canvas",
      "drawings": [
        {
          "points": [
            {
              "force": 1,
              "version": 1,
              "previous": {
                "y": 144,
                "x": 193.5
              },
              "location": {
                "y": 144,
                "x": 193.5
              },
              "isPredictive": false,
              "_type": "point"
            },
            {
              "force": 1,
              "version": 1,
              "previous": {
                "y": 224.5,
                "x": 191
              },
              "location": {
                "y": 225,
                "x": 191
              },
              "isPredictive": false,
              "_type": "point"
            }
          ],
          "isCulled": false,
          "metadata": {},
          "color": {
            "name": "black",
            "green": 0,
            "red": 0,
            "blue": 0,
            "alpha": 1
          },
          "_type": "drawing",
          "count": 2,
          "tool": {
            "force": 1,
            "name": "pen",
            "version": 1,
            "lineWidth": 16,
            "_type": "tool"
          },
          "version": 1,
          "size": {
            "height": 1054,
            "width": 826
          },
          "smoothing": {
            "name": "catmull-rom",
            "parameters": {
              "granularity": 8
            }
          },
          "drawingID": "655948C7-8D55-457F-8189-B6B4FA594FC4"
        }
      ],
      "index": 0
    }
  ],
  "header": {
    "version": 1,
    "_type": "header",
    "projectID": "37364725-79C0-4DAB-B61B-213DCEB192D1"
  },
  "_type": "project"
}

```

### Project

The full project structure.

##### `header` (Object)

The document header.

##### `canvases` (Array)

An array of Canvas object.

The array isn't guaranteed to be in any order.

### Canvas

A single Canvas of drawings. (Think pages)

##### `drawings` (Array)

The array of drawings. In the order they were created.

##### `index` (Integer)

The page number of the canvas. There shouldn't be any duplicated canvas index's in a Project.

### Drawing

A single drawing in a canvas.

##### `points` (Array)

All the points in the order they were created.

##### `drawingID` (v4 UUID)

The id of the drawing

##### `version` (Integer)

The version of the JSON structure.

##### `smoothing` (Integer)

The smoothing rate that should be used when drawing this path. (Catmull–Rom spline granularity)

##### `size` (Object)

The canvas size for the drawing. All drawings coordinate system is from the top left corner.

##### `count` (Integer)

Number of points in this drawing.

##### `meta` (Object)

Additional information about the drawing.

Used to store the data for a "text" tool drawing.

##### `tool` (Tool)

The tool used to create this drawing.

##### `isCulled` (Bool)

Indicates if the drawing should be culled from the render tree.

### Tool

The tool used to make the drawing.

### Point

The individual points that make up the drawing's path
