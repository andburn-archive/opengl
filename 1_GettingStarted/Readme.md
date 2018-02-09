## Getting Started

### Creating a Window

We need a window and an OpenGL context to draw in. This is OS specific, libraries exist to help e.g. GLUT, SDL, SFML and GLFW.
Using GLFW we can create an OpenGL context, as well as window with parameters and also handle user input. It also provides callbacks for useful events, such as user input or window resizing.

Another OS specific issue is the location of the OpenGL functions provided by a particular graphics card driver. GLAD is a library that helps to simplify this process.

Double buffering is a technique that makes changes to a secondary buffer object, then when complete updates the main buffer in one go, rather than updating the main buffer incrementally. Resulting in smoother frame transitions.

See [the code](1_GettingStarted/Hello/main.cpp) for actual usage.

### Basic Triangle

The graphics pipeline takes a 3D object and ouputs 2D pixels to the screen. The main interactions a programmer has with the pipeline is the with the vertex and fragment shader programs. 

The vertex shader operates on a 3D vertex and ouputs a 3D vertex that has been manipulated in some way by the program. The fragment shader takes a rasterized fragment and is used to determine the final colour of the output pixel.

OpenGL uses normalized device coordinates (NDC) to define vertices, where *x*, *y* and *z* range from *-1* to *+1*.

To send vertices to the vertex shader we need to store them in a *vertex buffer object* (VBO). Buffer are generated using:

```c
unsigned int VBO;
glGenBuffers(1, &VBO); // first arg is num of buffers to gen
```

A buffer needs to bound to an OpenGL buffer type to be usable, for a VBO the type is `GL_ARRAY_BUFFER` and its bound using:

```c
glBindBuffer(GL_ARRAY_BUFFER, VBO);
```

After the buffer is bound any buffer operations on the `GL_ARRAY_BUFFER` type will effect the *VBO* object. The vertex data can be copied into the buffer with:

```c
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
```

The fourth arg of `glBufferData` indicates how changeable the data is likely to be, `GL_STATIC_DRAW` means it will chnage very rarely, other options are `GL_DYNAMIC_DRAW` and `GL_STREAM_DRAW` for different degrees of dynamic data.

Shaders are separate programs written in the OpenGL Shading Language (GLSL). The most basic of vertex shaders can be seen below.

```glsl
#version 330 core
layout (location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);
}
```

A shader program begins with a version declaration and optionally a profile, in the example GLSL 3.3 and the core profile. All input vertex attributes are defined with the *in* keyword. In this case the location of the attribute is also given with `layout (location = 0)`, this is used later to send the shader the vertex data to the correct place. The ouptut vertex is assigned to `gl_Position`.

In a similar way to buffer creation we must create a shader object, and assign the source (a string in this case) to the object, then finally compile the shader for use.

```c
unsigned int vertexShader;
vertexShader = glCreateShader(GL_VERTEX_SHADER);
glShaderSource(vertexShader, 1, &vertexShaderSource, NULL);
glCompileShader(vertexShader);
```

Fragment shaders are created in analagous manner, where the code would specify `out` vectors.

```glsl
#version 330 core
out vec4 FragColor;

void main()
{
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);
}
```

Next, the two shaders need to be attached to a shader program.

```c
unsigned int shaderProgram;
shaderProgram = glCreateProgram();
glAttachShader(shaderProgram, vertexShader);
glAttachShader(shaderProgram, fragmentShader);
glLinkProgram(shaderProgram);
glUseProgram(shaderProgram);
```

The shader compilation and linking procedures can be checked for errors, see [the code](1_GettingStarted/Hello/main.cpp).

The next step is to define what data we will give to the vertex shader, vertex attributes allow us to send arbitrary data to the shader. We define it with `glVectexAttribPointer`, for example:

```c
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0); // references location set within the shader
```

A **vertex array object** (VAO) allows us to essentially save all this *vertex buffer* configuration, meaning it can be easily re-used. In fact, such an object is required by OpenGL Core. The definitino is similar to a *VBO*.

```c
unsigned int VAO;
glGenVertexArrays(1, &VAO);
glBindVertexArray(VAO);
// bind the VBO (saved by VAO)
glBindBuffer(GL_ARRAY_BUFFER, VBO);
glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), (void*)0);
glEnableVertexAttribArray(0);  
// [render loop]
glUseProgram(shaderProgram);
glBindVertexArray(VAO);
```

To eventually draw the triangle we use `glDrawArrays(GL_TRIANGLES, 0, 3);`

A final type of buffer to mention is an **Element Buffer Object** (EBO). Used when we want to draw multiple objects from a set of vertices, say two triangles to make a rectangle. Instead of duplicating vertices the EBO is an array of indices into the vertex buffer. A *VAO* will also keep track of a bound *EBO*.