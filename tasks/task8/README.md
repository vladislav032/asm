Многопоточный сумматор массива — программа разделяет массив чисел между двумя потоками, каждый из которых вычисляет частичную сумму своей половины.
Синхронизация через события — использует объекты Event для координации работы потоков и ожидания их завершения.
Вывод результатов — объединяет частичные суммы и выводит общий результат, корректно освобождая ресурсы (дескрипторы потоков и событий).