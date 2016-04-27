var webpack = require('webpack')
var ExtractTextPlugin = require('extract-text-webpack-plugin')
var sassOptions = 'indentedSyntax=true&includePaths=' + __dirname

module.exports = {
    entry: {
        'src/app': './.build/app.js'
    },
    output: {
        path: __dirname + '/dist',
        filename: '[name].js',
        library: ["bundles", "[name]"],
        libaryTarget: "var",
    },
    module: {
        loaders: [
            {
                test: /\.html$/,
                exclude: /node_modules|elm-stuff/,
                loader: 'file?name=[name].[ext]',
            },
            {
                test: /\.sass$/,
                exclude: /node_modules!elm-stuff/,
                loader: ExtractTextPlugin.extract('css-loader!sass-loader?'+sassOptions)
            },
            {
                test: /\.elm$/,
                exclude: /node_modules|elm-stuff/,
                loader: 'elm-webpack',
            },
        ],
        noParse: /\.elm$/,
    },
    devServer: {
        inline: true,
        stats: { color: true },
        noInfo: true,
    },
    plugins: [
        new ExtractTextPlugin("css/app.css"),
    ]
}
