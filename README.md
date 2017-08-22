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
              "isPredictive": false,
              "previous": {
                "xOffset": 0.17805755395683454,
                "yOffset": 0.10754716981132076
              },
              "location": {
                "xOffset": 0.17805755395683454,
                "yOffset": 0.10754716981132076
              },
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
          "tool": {
            "force": 1,
            "name": "pen",
            "version": 1,
            "lineWidth": 16,
            "_type": "tool"
          },
          "version": 1,
          "isSmoothingEnabled": true,
          "drawingID": "E73CD97C-C592-4F47-A235-669ACAAFBCE7"
        },
        {
          "points": [
            {
              "force": 1,
              "isPredictive": false,
              "previous": {
                "xOffset": 0.32553956834532372,
                "yOffset": 0.10754716981132076
              },
              "location": {
                "xOffset": 0.32553956834532372,
                "yOffset": 0.10754716981132076
              },
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
          "tool": {
            "force": 1,
            "name": "pen",
            "version": 1,
            "lineWidth": 16,
            "_type": "tool"
          },
          "version": 1,
          "isSmoothingEnabled": true,
          "drawingID": "0C97B68D-2E9E-47C6-BB05-2397B6EAC30D"
        }
      ],
      "index": 0
    }
  ],
  "header": {
    "version": 1,
    "_type": "header",
    "projectID": "DA5C9D8A-3F63-49BA-80D0-5DEAE3CC82FB"
  },
  "_type": "project"
}
```
