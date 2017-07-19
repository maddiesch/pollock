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
                "y": 186,
                "x": 276.5
              },
              "location": {
                "y": 186,
                "x": 276.5
              },
              "isPredictive": false,
              "_type": "point"
            },
            {
              "force": 1,
              "version": 1,
              "previous": {
                "y": 186,
                "x": 276.5
              },
              "location": {
                "y": 186,
                "x": 276.5
              },
              "isPredictive": false,
              "_type": "point"
            }
          ],
          "isCulled": false,
          "metadata": {},
          "_type": "drawing",
          "count": 2,
          "tool": {
            "force": 8,
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
          "smoothing": 8,
          "drawingID": "A167E04F-2CB0-42D6-87F6-E1A437B64E55"
        },
        {
          "points": [
            {
              "force": 1,
              "version": 1,
              "previous": {
                "y": 184.5,
                "x": 350
              },
              "location": {
                "y": 184.5,
                "x": 350
              },
              "isPredictive": false,
              "_type": "point"
            },
            {
              "force": 1,
              "version": 1,
              "previous": {
                "y": 184.5,
                "x": 350
              },
              "location": {
                "y": 184.5,
                "x": 350
              },
              "isPredictive": false,
              "_type": "point"
            }
          ],
          "isCulled": false,
          "metadata": {},
          "_type": "drawing",
          "count": 2,
          "tool": {
            "force": 8,
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
          "smoothing": 8,
          "drawingID": "404DCEFC-67F8-48BE-92EB-C187386583F3"
        }
      ],
      "index": 0
    }
  ],
  "header": {
    "projectID": "38F83390-9E0F-432D-A438-3CFB861B8F57",
    "version": 1,
    "_type": "header"
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
